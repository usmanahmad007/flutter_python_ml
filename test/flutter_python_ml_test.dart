import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_python_ml/flutter_python_ml.dart';
import 'package:flutter_python_ml/flutter_python_ml_platform_interface.dart';
import 'package:flutter_python_ml/flutter_python_ml_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterPythonMlPlatform
    with MockPlatformInterfaceMixin
    implements FlutterPythonMlPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('Android 14');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Plugin Setup', () {
    test('$MethodChannelFlutterPythonMl is the default instance', () {
      expect(FlutterPythonMlPlatform.instance,
          isInstanceOf<MethodChannelFlutterPythonMl>());
    });

    test('getPlatformVersion returns mock version', () async {
      final plugin = FlutterPythonMl();
      FlutterPythonMlPlatform.instance = MockFlutterPythonMlPlatform();
      expect(await plugin.getPlatformVersion(), 'Android 14');
    });
  });

  group('TensorData Tests', () {
    test('TensorData fromVector and calculations', () {
      final tensor = TensorData.fromVector([1.0, 5.0, 3.0, 2.0]);
      expect(tensor.shape, [4]);
      expect(tensor.totalElements, 4);
      expect(tensor.rank, 1);
      expect(tensor.argmax(), 1); // 5.0 at index 1

      final softmax = tensor.softmax();
      expect(softmax.shape, [4]);
      final sum = softmax.toFloatList().reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });

    test('TensorData fromMatrix2D and reshape', () {
      final matrix = TensorData.fromMatrix2D([
        [1.0, 2.0],
        [3.0, 4.0],
      ]);
      expect(matrix.shape, [2, 2]);
      expect(matrix.totalElements, 4);
      expect(matrix.rank, 2);

      final flattened = matrix.flatten();
      expect(flattened.shape, [4]);
      expect(flattened.data, [1.0, 2.0, 3.0, 4.0]);

      final reshaped = matrix.reshape([4, 1]);
      expect(reshaped.shape, [4, 1]);

      final mat2d = matrix.toMatrix2D();
      expect(mat2d.length, 2);
      expect(mat2d[0], [1.0, 2.0]);
    });

    test('TensorData oneHot encoding and normalization', () {
      final oneHot = TensorData.oneHot(2, 4);
      expect(oneHot.shape, [4]);
      expect(oneHot.data, [0.0, 0.0, 1.0, 0.0]);

      final tensor = TensorData.fromVector([10.0, 20.0, 30.0]);
      final normalized = tensor.normalize(mean: 20.0, std: 10.0);
      expect(normalized.toFloatList(), [-1.0, 0.0, 1.0]);
    });

    test('TensorData JSON serialization', () {
      final original = TensorData.fromVector([4.5, 6.7]);
      final json = original.toJson();
      final decoded = TensorData.fromJson(json);

      expect(decoded.shape, original.shape);
      expect(decoded.toFloatList(), original.toFloatList());
    });
  });

  group('PythonBridge & Mock Engine Tests', () {
    late PythonBridge bridge;

    setUp(() {
      bridge = PythonBridge(engine: MockPythonEngine());
    });

    tearDown(() async {
      await bridge.dispose();
    });

    test('executeScript runs successfully on mock engine', () async {
      final result = await bridge.executeScript('print("Hello from Python")');
      expect(result.isSuccess, true);
      expect(result.stdout, contains('Mock Python Engine'));
      expect(result.stdout, contains('Hello from Python'));
    });

    test('callFunction runs Iris classification in Python mock', () async {
      final result = await bridge.callFunction(
        'models/iris.py',
        'predict_iris',
        keywordArgs: {
          'features': [5.1, 3.5, 1.4, 0.2],
        },
      );

      expect(result.isSuccess, true);
      expect(result.result, isA<Map>());
      final map = result.result as Map;
      expect(map['label'], 'setosa');
      expect(map['confidence'], greaterThan(0.9));
    });

    test('callFunction runs House Price regression in Python mock', () async {
      final result = await bridge.callFunction(
        'models/house_pricing.py',
        'predict_price',
        keywordArgs: {
          'features': [2000.0, 3.0, 2.0], // 2000 sqft, 3 beds, 2 baths
        },
      );

      expect(result.isSuccess, true);
      expect(result.result['predicted_price'], greaterThan(400000.0));
    });

    test('callFunction runs Sentiment Analysis in Python mock', () async {
      final result = await bridge.callFunction(
        'models/nlp_sentiment.py',
        'predict_sentiment',
        keywordArgs: {
          'text': 'This on-device ML library is super fast and amazing!'
        },
      );

      expect(result.isSuccess, true);
      expect(result.result['label'], 'POSITIVE');
    });
  });

  group('PythonMLModel High-Level Abstraction Tests', () {
    test('Iris Classifier Model lifecycle and predictions', () async {
      final bridge = PythonBridge(engine: MockPythonEngine());
      final model = PythonMLModel(
        scriptPath: 'assets/models/iris_classifier.py',
        predictFunction: 'predict_iris',
        labels: ['setosa', 'versicolor', 'virginica'],
        bridge: bridge,
      );

      expect(model.status, ModelStatus.uninitialized);
      await model.initialize();
      expect(model.status, ModelStatus.ready);
      expect(model.isReady, true);

      // 1. Predict Setosa
      final p1 =
          await model.predict(TensorData.fromVector([5.1, 3.5, 1.4, 0.2]));
      expect(p1.predictedLabel, 'setosa');
      expect(p1.confidence, greaterThan(0.9));
      expect(p1.latencyMs, greaterThan(0.0));

      // 2. Predict Versicolor
      final p2 =
          await model.predict(TensorData.fromVector([6.0, 2.8, 4.0, 1.2]));
      expect(p2.predictedLabel, 'versicolor');

      // 3. Predict Virginica
      final p3 =
          await model.predict(TensorData.fromVector([7.2, 3.0, 6.0, 2.1]));
      expect(p3.predictedLabel, 'virginica');

      // 4. Batch Prediction
      final batch = await model.predictBatch([
        [5.1, 3.5, 1.4, 0.2],
        [7.2, 3.0, 6.0, 2.1],
      ]);
      expect(batch.length, 2);
      expect(batch[0].predictedLabel, 'setosa');
      expect(batch[1].predictedLabel, 'virginica');

      model.dispose();
      expect(model.status, ModelStatus.disposed);
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('PythonConsoleView renders and captures stdout logs',
        (tester) async {
      final bridge =
          PythonBridge(engine: MockPythonEngine(simulatedDelay: Duration.zero));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PythonConsoleView(bridge: bridge),
          ),
        ),
      );

      expect(find.text('Python Runtime Output'), findsOneWidget);

      // Trigger script to emit log
      await bridge.executeScript('print("Test log from Python")');
      await tester.pump();

      expect(find.textContaining('Mock Python Engine'), findsOneWidget);
    });

    testWidgets('ModelInferenceCard renders and triggers prediction',
        (tester) async {
      final bridge = PythonBridge(engine: MockPythonEngine());
      final model = PythonMLModel(
        scriptPath: 'assets/models/iris.py',
        predictFunction: 'predict_iris',
        labels: ['setosa', 'versicolor', 'virginica'],
        bridge: bridge,
      );

      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModelInferenceCard(
                model: model,
                title: 'Iris Flower Classifier',
                description: 'Classifies species on device',
                onPredictPressed: () => clicked = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Iris Flower Classifier'), findsOneWidget);
      expect(find.text('STANDBY'), findsOneWidget);

      await tester.tap(find.text('Run Python Model'));
      expect(clicked, true);
    });

    testWidgets('TensorVisualizer renders tensor elements', (tester) async {
      final tensor = TensorData.fromVector([1.23, 4.56, 7.89]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensorVisualizer(
              tensor: tensor,
              title: 'Feature Vector',
            ),
          ),
        ),
      );

      expect(find.text('Feature Vector'), findsOneWidget);
      expect(find.text('1.23'), findsOneWidget);
      expect(find.text('4.56'), findsOneWidget);
      expect(find.text('7.89'), findsOneWidget);
    });
  });

  group('DartPythonInterpreter Tests', () {
    test(
        'executes calculate_metrics function with prints and returns dictionary',
        () {
      final logs = <String>[];
      final interpreter = DartPythonInterpreter(
        onStdout: logs.add,
      );

      const script = '''
def calculate_metrics(values):
    import math
    mean = sum(values) / len(values)
    variance = sum((x - mean) ** 2 for x in values) / len(values)
    return {
        "count": len(values),
        "mean": round(mean, 3),
        "std_dev": round(math.sqrt(variance), 3),
        "max": max(values),
        "min": min(values),
    }

result = calculate_metrics([12.5, 45.2, 78.1, 99.4, 32.8])
print("Metrics computed:", result)
''';

      interpreter.execute(script);
      expect(logs.length, 1);
      expect(logs.first, contains('Metrics computed:'));
      expect(logs.first, contains("'count': 5"));
      expect(logs.first, contains("'mean': 53.6"));
      expect(logs.first, contains("'std_dev': 31.274"));
    });

    test('executes for loops, ranges, list comprehensions, and math functions',
        () {
      final logs = <String>[];
      final interpreter = DartPythonInterpreter(
        onStdout: logs.add,
      );

      interpreter.execute('''
for i in range(1, 4):
    print("Epoch", i)
squares = [x * x for x in range(4)]
print("Squares:", squares)
import math
print("Sqrt:", math.sqrt(100))
''');

      expect(logs, contains('Epoch 1'));
      expect(logs, contains('Epoch 2'));
      expect(logs, contains('Epoch 3'));
      expect(logs, contains('Squares: [0, 1, 4, 9]'));
      expect(logs, contains('Sqrt: 10.0'));
    });
  });
}
