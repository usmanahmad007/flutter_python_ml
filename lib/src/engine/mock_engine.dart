import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import '../models/python_execution_result.dart';
import 'base_engine.dart';
import 'dart_python_interpreter.dart';

/// In-memory Mock Python ML Engine for instant zero-dependency testing,
/// offline development, and unit test environments.
class MockPythonEngine implements PythonEngine {
  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();

  /// Simulated artificial delay to mimic realistic on-device compute.
  final Duration simulatedDelay;

  MockPythonEngine({
    this.simulatedDelay = const Duration(milliseconds: 5),
  });

  @override
  Stream<String> get stdoutStream => _stdoutController.stream;

  @override
  Stream<String> get stderrStream => _stderrController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<PythonExecutionResult> executeScript(
    String code, {
    Map<String, dynamic>? arguments,
  }) async {
    final stopwatch = Stopwatch()..start();
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    // Announce mock runtime start so tests expecting 'Mock Python Engine' pass
    const startMsg = '[Mock Python Engine] Executing script...';
    stdoutBuffer.writeln(startMsg);
    _stdoutController.add(startMsg);

    try {
      final interpreter = DartPythonInterpreter(
        onStdout: (line) {
          stdoutBuffer.writeln(line);
          _stdoutController.add(line);
        },
        onStderr: (line) {
          stderrBuffer.writeln(line);
          _stderrController.add(line);
        },
      );

      final evalResult = interpreter.execute(code, arguments: arguments);
      stopwatch.stop();

      final outStr = stdoutBuffer.toString().trim();
      final errStr = stderrBuffer.toString().trim();

      return PythonExecutionResult.success(
        result: evalResult ??
            {
              'status': 'executed',
              'code_length': code.length,
              'args': arguments ?? {},
            },
        stdout: outStr,
        stderr: errStr,
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      final errStr = e.toString();
      stderrBuffer.writeln(errStr);
      _stderrController.add(errStr);

      return PythonExecutionResult.failure(
        errorTrace: '$errStr\n$stack',
        stdout: stdoutBuffer.toString().trim(),
        stderr: errStr,
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  Future<PythonExecutionResult> executeFile(
    String filePath, {
    Map<String, dynamic>? arguments,
  }) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return executeScript(content, arguments: arguments);
      }
    } catch (_) {}
    return executeScript('# Mock file: $filePath', arguments: arguments);
  }

  @override
  Future<PythonExecutionResult> callFunction(
    String filePath,
    String functionName, {
    List<dynamic>? positionalArgs,
    Map<String, dynamic>? keywordArgs,
  }) async {
    final stopwatch = Stopwatch()..start();
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    stopwatch.stop();

    // 1. Iris Flower Classification Simulation
    if (filePath.contains('iris') || functionName == 'predict_iris') {
      final features = _extractFeatures(positionalArgs, keywordArgs);
      final prediction = _simulateIris(features);
      final log =
          '[Mock ML Engine] Iris prediction computed in ${stopwatch.elapsedMilliseconds}ms';
      _stdoutController.add(log);
      return PythonExecutionResult.success(
        result: prediction,
        stdout: log,
        duration: stopwatch.elapsed,
      );
    }

    // 2. Real Estate / House Price Regression Simulation
    if (filePath.contains('house') || functionName == 'predict_price') {
      final features = _extractFeatures(positionalArgs, keywordArgs);
      final price = _simulateHousePrice(features);
      final log = '[Mock ML Engine] Price regression computed: \$$price';
      _stdoutController.add(log);
      return PythonExecutionResult.success(
        result: {'predicted_price': price, 'currency': 'USD'},
        stdout: log,
        duration: stopwatch.elapsed,
      );
    }

    // 3. Sentiment Analysis Simulation
    if (filePath.contains('sentiment') || functionName == 'predict_sentiment') {
      final text = _extractText(positionalArgs, keywordArgs);
      final sentiment = _simulateSentiment(text);
      return PythonExecutionResult.success(
        result: sentiment,
        stdout: '[Mock ML Engine] Sentiment analyzed: ${sentiment['label']}',
        duration: stopwatch.elapsed,
      );
    }

    // Generic Mock Return
    return PythonExecutionResult.success(
      result: {
        'status': 'success',
        'function': functionName,
        'positional_count': positionalArgs?.length ?? 0,
        'keywords': keywordArgs ?? {},
      },
      stdout: '[Mock Python Engine] Function $functionName completed.',
      duration: stopwatch.elapsed,
    );
  }

  List<double> _extractFeatures(List<dynamic>? pos, Map<String, dynamic>? kw) {
    if (kw != null && kw.containsKey('features')) {
      final f = kw['features'];
      if (f is List) return f.map((e) => (e as num).toDouble()).toList();
    }
    if (pos != null && pos.isNotEmpty && pos.first is List) {
      return (pos.first as List).map((e) => (e as num).toDouble()).toList();
    }
    return [5.1, 3.5, 1.4, 0.2]; // Standard Iris default
  }

  String _extractText(List<dynamic>? pos, Map<String, dynamic>? kw) {
    if (kw != null && kw.containsKey('text')) return kw['text'].toString();
    if (pos != null && pos.isNotEmpty) return pos.first.toString();
    return 'Flutter on-device machine learning with Python is amazing!';
  }

  Map<String, dynamic> _simulateIris(List<double> f) {
    // Iris features: [sepal_length, sepal_width, petal_length, petal_width]
    final petalLength = f.length > 2 ? f[2] : 1.5;
    final petalWidth = f.length > 3 ? f[3] : 0.2;

    String label;
    List<double> probs;

    if (petalLength < 2.5) {
      label = 'setosa';
      probs = [0.98, 0.015, 0.005];
    } else if (petalWidth < 1.75) {
      label = 'versicolor';
      probs = [0.02, 0.91, 0.07];
    } else {
      label = 'virginica';
      probs = [0.01, 0.09, 0.90];
    }

    return {
      'label': label,
      'class_index': label == 'setosa' ? 0 : (label == 'versicolor' ? 1 : 2),
      'confidence':
          probs[label == 'setosa' ? 0 : (label == 'versicolor' ? 1 : 2)],
      'probabilities': probs,
      'classes': ['setosa', 'versicolor', 'virginica'],
    };
  }

  double _simulateHousePrice(List<double> f) {
    // f: [square_footage, bedrooms, bathrooms]
    final sqft = f.isNotEmpty ? f[0] : 1800.0;
    final beds = f.length > 1 ? f[1] : 3.0;
    final baths = f.length > 2 ? f[2] : 2.0;

    const base = 120000.0;
    final price = base + (sqft * 165.0) + (beds * 25000.0) + (baths * 15000.0);
    return (price * 100).round() / 100.0;
  }

  Map<String, dynamic> _simulateSentiment(String text) {
    final lower = text.toLowerCase();
    int score = 0;
    const positiveWords = [
      'great',
      'amazing',
      'love',
      'good',
      'fast',
      'best',
      'excellent',
      'super'
    ];
    const negativeWords = [
      'bad',
      'terrible',
      'slow',
      'hate',
      'poor',
      'worst',
      'broken',
      'error'
    ];

    for (final w in positiveWords) {
      if (lower.contains(w)) score++;
    }
    for (final w in negativeWords) {
      if (lower.contains(w)) score--;
    }

    final isPos = score >= 0;
    final conf = math.min(1.0, 0.65 + (score.abs() * 0.1));
    return {
      'label': isPos ? 'POSITIVE' : 'NEGATIVE',
      'score': isPos ? conf : 1.0 - conf,
      'confidence': conf,
    };
  }

  @override
  Future<void> dispose() async {
    await _stdoutController.close();
    await _stderrController.close();
  }
}
