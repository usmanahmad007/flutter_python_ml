import 'tensor_data.dart';

/// Represents the output of a local on-device machine learning inference.
class MLPrediction {
  /// The raw return value received from Python (can be a Map, List, or number).
  final dynamic rawOutput;

  /// Structured tensor if the output is numeric or multi-dimensional.
  final TensorData? tensor;

  /// Human-readable predicted class or category name, e.g. "setosa", "malignant", "cat".
  final String? predictedLabel;

  /// Confidence score or maximum class probability between 0.0 and 1.0.
  final double? confidence;

  /// Softmax probability distribution over all target classes.
  final List<double>? probabilities;

  /// Time taken to complete the local Python inference.
  final Duration latency;

  /// Timestamp when inference completed.
  final DateTime timestamp;

  /// Custom metadata or feature weights returned by the model.
  final Map<String, dynamic> metadata;

  MLPrediction({
    required this.rawOutput,
    this.tensor,
    this.predictedLabel,
    this.confidence,
    this.probabilities,
    required this.latency,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  /// Inference latency in floating-point milliseconds.
  double get latencyMs => latency.inMicroseconds / 1000.0;

  Map<String, dynamic> toJson() => {
        'rawOutput': rawOutput,
        if (tensor != null) 'tensor': tensor!.toJson(),
        if (predictedLabel != null) 'predictedLabel': predictedLabel,
        if (confidence != null) 'confidence': confidence,
        if (probabilities != null) 'probabilities': probabilities,
        'latencyMs': latencyMs,
        'timestamp': timestamp.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  @override
  String toString() {
    final confStr = confidence != null
        ? '${(confidence! * 100).toStringAsFixed(1)}%'
        : 'N/A';
    return 'MLPrediction(label: $predictedLabel, confidence: $confStr, latency: ${latencyMs.toStringAsFixed(2)}ms)';
  }
}
