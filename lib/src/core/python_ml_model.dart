import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/ml_prediction.dart';
import '../models/python_execution_result.dart';
import '../models/tensor_data.dart';
import 'python_bridge.dart';

/// Lifecycle status of an on-device Python Machine Learning model.
enum ModelStatus {
  uninitialized,
  loading,
  ready,
  predicting,
  error,
  disposed,
}

/// High-level Machine Learning Model abstraction wrapping local Python scripts,
/// preprocessors, weight initializers, and tensor inference pipelines.
class PythonMLModel extends ChangeNotifier {
  /// Path to the local Python script (`.py`) containing model definitions.
  final String scriptPath;

  /// Function name in the Python file responsible for running inference (default: 'predict').
  final String predictFunction;

  /// Optional one-time initialization function (e.g. `load_weights` or `init_model`).
  final String? initFunction;

  /// Target classification labels (e.g. `['setosa', 'versicolor', 'virginica']`).
  final List<String>? labels;

  /// Optional input preprocessing transformation hook.
  final TensorData Function(dynamic rawInput)? preprocessor;

  /// Optional custom postprocessing pipeline hook.
  final MLPrediction Function(dynamic rawOutput, Duration latency)?
      postprocessor;

  /// The underlying Python bridge used for communication.
  final PythonBridge bridge;

  ModelStatus _status = ModelStatus.uninitialized;
  String? _lastError;
  MLPrediction? _lastPrediction;

  PythonMLModel({
    required this.scriptPath,
    this.predictFunction = 'predict',
    this.initFunction,
    this.labels,
    this.preprocessor,
    this.postprocessor,
    PythonBridge? bridge,
  }) : bridge = bridge ?? PythonBridge.instance;

  ModelStatus get status => _status;
  bool get isReady => _status == ModelStatus.ready;
  String? get lastError => _lastError;
  MLPrediction? get lastPrediction => _lastPrediction;

  /// Initializes the model, pre-loading weights or dependencies into Python memory.
  Future<void> initialize({Map<String, dynamic>? initArgs}) async {
    if (_status == ModelStatus.ready || _status == ModelStatus.loading) return;

    _status = ModelStatus.loading;
    _lastError = null;
    notifyListeners();

    try {
      await bridge.initialize();

      if (initFunction != null && initFunction!.isNotEmpty) {
        final initResult = await bridge.callFunction(
          scriptPath,
          initFunction!,
          keywordArgs: initArgs,
        );
        if (!initResult.isSuccess) {
          throw PythonExecutionException(
            initResult.errorTrace ?? 'Model initialization failed.',
            traceback: initResult.errorTrace,
          );
        }
      }

      _status = ModelStatus.ready;
      notifyListeners();
    } catch (e) {
      _status = ModelStatus.error;
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Runs local on-device inference on [input] and returns an [MLPrediction].
  Future<MLPrediction> predict(dynamic input) async {
    if (_status != ModelStatus.ready) {
      await initialize();
    }

    _status = ModelStatus.predicting;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Run Preprocessing if provided
      dynamic processedInput = input;
      if (preprocessor != null) {
        processedInput = preprocessor!(input);
      }

      // Convert TensorData to JSON/array if needed
      dynamic serializedArg = processedInput;
      if (processedInput is TensorData) {
        serializedArg = processedInput.data;
      }

      // 2. Execute Python Predict Function
      final execResult = await bridge.callFunction(
        scriptPath,
        predictFunction,
        keywordArgs: serializedArg is Map<String, dynamic>
            ? serializedArg
            : {'features': serializedArg},
        positionalArgs: serializedArg is List ? [serializedArg] : null,
      );

      stopwatch.stop();

      if (!execResult.isSuccess) {
        throw PythonExecutionException(
          execResult.errorTrace ?? 'Inference error in $scriptPath',
          traceback: execResult.errorTrace,
        );
      }

      // 3. Postprocessing & Output Structuring
      MLPrediction prediction;
      if (postprocessor != null) {
        prediction = postprocessor!(execResult.result, stopwatch.elapsed);
      } else {
        prediction = _parsePrediction(execResult.result, stopwatch.elapsed);
      }

      _lastPrediction = prediction;
      _status = ModelStatus.ready;
      notifyListeners();
      return prediction;
    } catch (e) {
      _status = ModelStatus.error;
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Runs inference across a batch of inputs in sequence.
  Future<List<MLPrediction>> predictBatch(List<dynamic> batch) async {
    final predictions = <MLPrediction>[];
    for (final item in batch) {
      final p = await predict(item);
      predictions.add(p);
    }
    return predictions;
  }

  /// Internal parser mapping generic Python dictionaries and arrays into structured [MLPrediction].
  MLPrediction _parsePrediction(dynamic result, Duration latency) {
    String? predictedLabel;
    double? confidence;
    List<double>? probabilities;
    TensorData? tensor;

    if (result is Map) {
      final map = Map<String, dynamic>.from(result);
      if (map.containsKey('label')) predictedLabel = map['label']?.toString();
      if (map.containsKey('predicted_label'))
        predictedLabel = map['predicted_label']?.toString();
      if (map.containsKey('confidence'))
        confidence = (map['confidence'] as num?)?.toDouble();
      if (map.containsKey('probabilities') && map['probabilities'] is List) {
        probabilities = (map['probabilities'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }
      if (map.containsKey('class_index') && labels != null) {
        final idx = (map['class_index'] as num).toInt();
        if (idx >= 0 && idx < labels!.length) {
          predictedLabel ??= labels![idx];
        }
      }
      return MLPrediction(
        rawOutput: result,
        predictedLabel: predictedLabel,
        confidence: confidence,
        probabilities: probabilities,
        latency: latency,
        metadata: map,
      );
    } else if (result is List) {
      final floatList = result.map((e) => (e as num).toDouble()).toList();
      tensor = TensorData(shape: [floatList.length], data: floatList);

      // If classification labels are available and output matches length, compute argmax
      if (labels != null && labels!.length == floatList.length) {
        final softmax = tensor.softmax();
        final maxIdx = softmax.argmax();
        predictedLabel = labels![maxIdx];
        confidence = softmax.toFloatList()[maxIdx];
        probabilities = softmax.toFloatList();
      }

      return MLPrediction(
        rawOutput: result,
        tensor: tensor,
        predictedLabel: predictedLabel,
        confidence: confidence,
        probabilities: probabilities,
        latency: latency,
      );
    } else if (result is num) {
      return MLPrediction(
        rawOutput: result,
        predictedLabel: result.toString(),
        confidence: 1.0,
        latency: latency,
      );
    } else {
      return MLPrediction(
        rawOutput: result,
        predictedLabel: result.toString(),
        latency: latency,
      );
    }
  }

  @override
  void dispose() {
    _status = ModelStatus.disposed;
    super.dispose();
  }
}
