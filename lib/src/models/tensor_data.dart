import 'dart:math' as math;
import 'dart:typed_data';

/// Data types supported by [TensorData].
enum TensorDType {
  float32,
  int64,
  int32,
  uint8,
  string,
}

/// A multi-dimensional tensor container optimized for on-device ML inference,
/// feature engineering, and direct serialization with Python scripts.
class TensorData {
  /// The dimensions of the tensor, e.g. `[1, 4]` or `[28, 28, 1]`.
  final List<int> shape;

  /// The underlying numeric or object data type.
  final TensorDType dtype;

  /// The flattened or nested elements of the tensor.
  final List<dynamic> data;

  TensorData({
    required this.shape,
    required List<dynamic> data,
    this.dtype = TensorDType.float32,
  }) : data = List.unmodifiable(data) {
    if (shape.isNotEmpty) {
      final expectedCount = shape.reduce((a, b) => a * b);
      if (data.length != expectedCount) {
        throw ArgumentError(
          'TensorData shape $shape expects $expectedCount elements, but received ${data.length} elements.',
        );
      }
    }
  }

  /// Creates a 1D tensor vector from numbers.
  factory TensorData.fromVector(
    List<num> vector, {
    TensorDType dtype = TensorDType.float32,
  }) {
    return TensorData(
      shape: [vector.length],
      data: vector
          .map((e) => dtype == TensorDType.float32 ? e.toDouble() : e.toInt())
          .toList(),
      dtype: dtype,
    );
  }

  /// Creates a 2D tensor matrix from rows of numbers.
  factory TensorData.fromMatrix2D(
    List<List<num>> matrix, {
    TensorDType dtype = TensorDType.float32,
  }) {
    if (matrix.isEmpty) {
      return TensorData(shape: [0, 0], data: [], dtype: dtype);
    }
    final rows = matrix.length;
    final cols = matrix.first.length;
    final flattened = <dynamic>[];
    for (final row in matrix) {
      if (row.length != cols) {
        throw ArgumentError(
            'All matrix rows must have the same column length: expected $cols, got ${row.length}');
      }
      for (final val in row) {
        flattened
            .add(dtype == TensorDType.float32 ? val.toDouble() : val.toInt());
      }
    }
    return TensorData(
      shape: [rows, cols],
      data: flattened,
      dtype: dtype,
    );
  }

  /// Creates a tensor of zeros with the specified shape.
  factory TensorData.zeros(
    List<int> shape, {
    TensorDType dtype = TensorDType.float32,
  }) {
    final count = shape.isEmpty ? 0 : shape.reduce((a, b) => a * b);
    return TensorData(
      shape: shape,
      data: List.filled(count, dtype == TensorDType.float32 ? 0.0 : 0),
      dtype: dtype,
    );
  }

  /// Creates a tensor of ones with the specified shape.
  factory TensorData.ones(
    List<int> shape, {
    TensorDType dtype = TensorDType.float32,
  }) {
    final count = shape.isEmpty ? 0 : shape.reduce((a, b) => a * b);
    return TensorData(
      shape: shape,
      data: List.filled(count, dtype == TensorDType.float32 ? 1.0 : 1),
      dtype: dtype,
    );
  }

  /// Generates a one-hot encoded 1D tensor.
  factory TensorData.oneHot(int classIndex, int numClasses) {
    if (classIndex < 0 || classIndex >= numClasses) {
      throw RangeError(
          'classIndex must be between 0 and ${numClasses - 1}, got $classIndex');
    }
    final list = List<double>.filled(numClasses, 0.0);
    list[classIndex] = 1.0;
    return TensorData(
        shape: [numClasses], data: list, dtype: TensorDType.float32);
  }

  /// Total number of elements in the tensor.
  int get totalElements => data.length;

  /// The tensor rank (number of dimensions).
  int get rank => shape.length;

  /// Returns the elements as a typed double list.
  List<double> toFloatList() {
    return data.map((e) => (e as num).toDouble()).toList();
  }

  /// Returns the elements as a native Float32List.
  Float32List toFloat32List() {
    return Float32List.fromList(toFloatList());
  }

  /// Returns the elements as a 2D matrix list if rank == 2.
  List<List<double>> toMatrix2D() {
    if (rank != 2) {
      throw StateError('Cannot convert tensor of rank $rank to 2D matrix.');
    }
    final rows = shape[0];
    final cols = shape[1];
    final matrix = <List<double>>[];
    for (int r = 0; r < rows; r++) {
      final start = r * cols;
      matrix.add(toFloatList().sublist(start, start + cols));
    }
    return matrix;
  }

  /// Returns the index of the highest numeric value (argmax).
  int argmax() {
    if (data.isEmpty) return -1;
    int maxIndex = 0;
    double maxVal = (data[0] as num).toDouble();
    for (int i = 1; i < data.length; i++) {
      final val = (data[i] as num).toDouble();
      if (val > maxVal) {
        maxVal = val;
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  /// Computes the softmax probability distribution across the tensor elements.
  TensorData softmax() {
    final floatVals = toFloatList();
    if (floatVals.isEmpty) return this;

    final maxVal = floatVals.reduce(math.max);
    final expVals = floatVals.map((e) => math.exp(e - maxVal)).toList();
    final sumExp = expVals.reduce((a, b) => a + b);

    final normalized =
        expVals.map((e) => e / (sumExp == 0 ? 1 : sumExp)).toList();
    return TensorData(
        shape: List.from(shape), data: normalized, dtype: TensorDType.float32);
  }

  /// Standardizes or normalizes tensor elements using mean and standard deviation.
  TensorData normalize({double mean = 0.0, double std = 1.0}) {
    if (std == 0) throw ArgumentError('Standard deviation cannot be zero.');
    final normalized = toFloatList().map((val) => (val - mean) / std).toList();
    return TensorData(
        shape: List.from(shape), data: normalized, dtype: TensorDType.float32);
  }

  /// Reshapes this tensor into new dimensions without copying underlying elements.
  TensorData reshape(List<int> newShape) {
    return TensorData(shape: newShape, data: data, dtype: dtype);
  }

  /// Flattens the tensor into a 1D vector.
  TensorData flatten() {
    return TensorData(shape: [data.length], data: data, dtype: dtype);
  }

  Map<String, dynamic> toJson() => {
        'shape': shape,
        'dtype': dtype.name,
        'data': data,
      };

  factory TensorData.fromJson(Map<String, dynamic> json) {
    final shape = (json['shape'] as List<dynamic>?)?.cast<int>() ?? [];
    final dtypeStr = json['dtype'] as String? ?? 'float32';
    final dtype = TensorDType.values.firstWhere(
      (e) => e.name == dtypeStr,
      orElse: () => TensorDType.float32,
    );
    final rawData = (json['data'] as List<dynamic>?) ?? [];
    return TensorData(shape: shape, data: rawData, dtype: dtype);
  }

  @override
  String toString() =>
      'TensorData(shape: $shape, dtype: ${dtype.name}, total: $totalElements)';
}
