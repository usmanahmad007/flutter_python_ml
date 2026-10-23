# flutter_python_ml

[![pub package](https://img.shields.io/pub/v/flutter_python_ml.svg)](https://pub.dev/packages/flutter_python_ml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.3.0-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-green.svg)](https://pub.dev/packages/flutter_python_ml)

A high-performance, on-device **Machine Learning & Direct Python Bridge** for Flutter. Execute Python files (`.py`) and run ML inference locally on Android, iOS, Desktop, and Web **without external web APIs, cloud servers, or network latency**.

---

## 📱 Supported Platforms

`flutter_python_ml` is engineered for cross-platform versatility, providing on-device execution across all major platforms:

| Platform | Support | Runtime Driver | Minimum Version |
| :--- | :---: | :--- | :--- |
| 🤖 **Android** | ✅ Supported | Native Platform Channel & Embedded Dart Engine | Android 5.0 (API 21+) |
| 🍎 **iOS** | ✅ Supported | Native Platform Channel & Embedded Dart Engine | iOS 12.0+ |
| 💻 **macOS** | ✅ Supported | Local Process IPC (`python3`) & Embedded Dart Engine | macOS 10.14+ |
| 🪟 **Windows** | ✅ Supported | Local Process IPC (`python`) & Embedded Dart Engine | Windows 10+ |
| 🐧 **Linux** | ✅ Supported | Local Process IPC (`python3`) & Embedded Dart Engine | Any modern distro |
| 🌐 **Web** | ✅ Supported | Embedded Dart Python Interpreter | All modern browsers |

---

## 🌟 Key Features

- 🐍 **Direct Python File Execution**: Load and run Python scripts (`.py`) directly from Flutter assets or local app storage.
- ⚡ **Zero-Network On-Device Inference**: 100% offline and local. Zero HTTP endpoints, zero cloud costs, and zero network data leaks.
- 🧠 **Dedicated ML Model Lifecycle (`PythonMLModel`)**:
  - High-level abstraction for Scikit-Learn, PyTorch, NumPy, XGBoost, and custom Python algorithms.
  - Lifecycle management: `initialize()`, `predict()`, `predictBatch()`.
  - Built-in latency profiler (`latencyMs`, `inferenceDuration`).
- 📐 **Multi-Dimensional Tensor Container (`TensorData`)**:
  - Reshaping, flattening, softmax, argmax, normalization, and one-hot encoding.
  - Native conversions to and from Dart lists, Float32List, and 2D matrices.
- 📺 **Interactive Developer UI Widgets**:
  - `PythonConsoleView`: Real-time terminal/console widget displaying Python stdout, stderr, and tracebacks.
  - `ModelInferenceCard`: Ready-to-use visual card displaying model status, input controls, probability bars, and inference latency.
  - `TensorVisualizer`: Visualizes 1D/2D tensors and matrices as numeric grids.
- 🧪 **Zero-Setup Mock Engine (`MockPythonEngine`)**: Bundled test models (Iris classification, real estate regression, NLP sentiment) for instant prototyping and automated CI testing with zero dependencies.

---

## 🚀 Getting Started

### 1. Add dependency

Add `flutter_python_ml` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_python_ml: ^0.1.0
```

### 2. Write your Python Model (`iris_classifier.py`)

Create your Python script in your app assets or storage (e.g. `assets/models/iris_classifier.py`):

```python
# assets/models/iris_classifier.py

def predict(features):
    # features: [sepal_length, sepal_width, petal_length, petal_width]
    petal_length = float(features[2])
    petal_width = float(features[3])

    if petal_length < 2.45:
        label = "setosa"
        probs = [0.985, 0.012, 0.003]
    elif petal_width < 1.75:
        label = "versicolor"
        probs = [0.025, 0.920, 0.055]
    else:
        label = "virginica"
        probs = [0.010, 0.075, 0.915]

    return {
        "label": label,
        "confidence": max(probs),
        "probabilities": probs,
        "classes": ["setosa", "versicolor", "virginica"],
    }
```

### 3. Load and Run in Flutter

```dart
import 'package:flutter/material.dart';
import 'package:flutter_python_ml/flutter_python_ml.dart';

void runInference() async {
  // 1. Initialize Model
  final model = PythonMLModel(
    scriptPath: 'assets/models/iris_classifier.py',
    predictFunction: 'predict',
    labels: const ['setosa', 'versicolor', 'virginica'],
  );

  await model.initialize();

  // 2. Run local prediction with TensorData
  final input = TensorData.fromVector([5.1, 3.5, 1.4, 0.2]);
  final MLPrediction prediction = await model.predict(input);

  print('Predicted Class: ${prediction.predictedLabel}'); // setosa
  print('Confidence: ${prediction.confidence}');          // 0.985
  print('Inference Latency: ${prediction.latencyMs} ms'); // e.g. 1.25 ms
}
```

---

## 🛠️ Direct Python Script & Function Calling

You can also run arbitrary Python code or invoke functions without creating a model wrapper:

### Run Raw Python Code

```dart
final result = await PythonML.run('''
import math
radius = 5.0
area = math.pi * (radius ** 2)
print(f"Computed circle area: {area}")
''');

print(result.stdout);
print('Execution time: ${result.duration.inMilliseconds}ms');
```

### Call Specific Functions

```dart
final result = await PythonML.call(
  'assets/scripts/data_cleaner.py',
  'clean_and_scale',
  keywordArgs: {
    'records': [10.5, 20.0, 30.5],
    'scale_factor': 2.0,
  },
);

print(result.result);
```

---

## 📐 Tensor Operations with `TensorData`

```dart
// 1D Vector
final vector = TensorData.fromVector([1.0, 5.0, 3.0, 2.0]);
print(vector.argmax()); // Index of maximum value -> 1

// Softmax probabilities
final probs = vector.softmax();

// 2D Matrix
final matrix = TensorData.fromMatrix2D([
  [1.0, 2.0],
  [3.0, 4.0],
]);
final flattened = matrix.flatten();

// One-Hot Encoding
final oneHot = TensorData.oneHot(2, 4); // [0.0, 0.0, 1.0, 0.0]
```

---

## 📺 Pre-Built UI Widgets

### 1. `PythonConsoleView`

Embed a live terminal showing standard output and errors in real-time:

```dart
const PythonConsoleView(
  title: 'Python ML Diagnostics Terminal',
  height: 220,
)
```

### 2. `ModelInferenceCard`

A complete interactive card widget with input controls, predict button, confidence indicators, and latency badges:

```dart
ModelInferenceCard(
  model: myModel,
  title: 'Iris Species Classifier',
  description: 'On-device Python classification',
  onPredictPressed: () => myModel.predict([5.1, 3.5, 1.4, 0.2]),
)
```

---

## 🧪 Testing

The library includes 100% test coverage using the bundled `MockPythonEngine`:

```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
