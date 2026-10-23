import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_python_ml/flutter_python_ml.dart';

void main() {
  runApp(const FlutterPythonMlApp());
}

class FlutterPythonMlApp extends StatelessWidget {
  const FlutterPythonMlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Python ML Direct Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PythonBridge _bridge = PythonBridge.instance;

  // 1. Iris Model State
  late PythonMLModel _irisModel;
  double _sepalLength = 5.1;
  double _sepalWidth = 3.5;
  double _petalLength = 1.4;
  double _petalWidth = 0.2;
  MLPrediction? _irisPrediction;

  // 2. House Price Model State
  late PythonMLModel _houseModel;
  double _sqft = 2200;
  double _bedrooms = 3;
  double _bathrooms = 2;
  MLPrediction? _housePrediction;

  // 3. Sentiment NLP Model State
  late PythonMLModel _sentimentModel;
  final TextEditingController _sentimentTextController = TextEditingController(
    text:
        'Flutter on-device machine learning with Python is fast and super easy!',
  );
  MLPrediction? _sentimentPrediction;

  // 4. Raw Python Code Editor State
  final TextEditingController _rawCodeController = TextEditingController(
    text: '''# Custom on-device Python execution
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
''',
  );

  bool _isUsingMockEngine = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initEnginesAndModels();
  }

  void _initEnginesAndModels() {
    // Default to embedded Dart Engine for 100% on-device zero-dependency execution
    if (_isUsingMockEngine) {
      _bridge.setEngine(MockPythonEngine());
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        _bridge.setEngine(PlatformChannelEngine());
      } else {
        _bridge.setEngine(LocalProcessEngine());
      }
    }

    _irisModel = PythonMLModel(
      scriptPath: 'assets/models/iris_classifier.py',
      predictFunction: 'predict',
      labels: const ['setosa', 'versicolor', 'virginica'],
      bridge: _bridge,
    );

    _houseModel = PythonMLModel(
      scriptPath: 'assets/models/house_pricing.py',
      predictFunction: 'predict',
      bridge: _bridge,
    );

    _sentimentModel = PythonMLModel(
      scriptPath: 'assets/models/sentiment_nlp.py',
      predictFunction: 'predict',
      bridge: _bridge,
    );
  }

  void _toggleEngine(bool useMock) {
    setState(() {
      _isUsingMockEngine = useMock;
      _initEnginesAndModels();
    });
  }

  Future<void> _runIrisPrediction() async {
    final pred = await _irisModel.predict(
      TensorData.fromVector(
          [_sepalLength, _sepalWidth, _petalLength, _petalWidth]),
    );
    setState(() => _irisPrediction = pred);
  }

  Future<void> _runHousePrediction() async {
    final pred = await _houseModel.predict({
      'sqft': _sqft,
      'beds': _bedrooms,
      'baths': _bathrooms,
    });
    setState(() => _housePrediction = pred);
  }

  Future<void> _runSentimentPrediction() async {
    final text = _sentimentTextController.text.trim();
    if (text.isEmpty) return;
    final pred = await _sentimentModel.predict({'text': text});
    setState(() => _sentimentPrediction = pred);
  }

  Future<void> _runRawPythonScript() async {
    final code = _rawCodeController.text;
    await _bridge.executeScript(code);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sentimentTextController.dispose();
    _rawCodeController.dispose();
    _irisModel.dispose();
    _houseModel.dispose();
    _sentimentModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_rounded, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 8),
            Text('Flutter Python ML',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(
                _isUsingMockEngine
                    ? 'Dart Engine'
                    : (Platform.isAndroid || Platform.isIOS
                        ? 'Platform Driver'
                        : 'Process IPC'),
                style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.cyanAccent),
              ),
              Switch(
                value: _isUsingMockEngine,
                activeColor: Colors.cyanAccent,
                onChanged: _toggleEngine,
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(icon: Icon(Icons.spa_rounded), text: 'Iris Classifier'),
            Tab(icon: Icon(Icons.home_work_rounded), text: 'House Regression'),
            Tab(icon: Icon(Icons.text_fields_rounded), text: 'NLP Sentiment'),
            Tab(icon: Icon(Icons.terminal_rounded), text: 'Python Console'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIrisTab(),
          _buildHouseTab(),
          _buildSentimentTab(),
          _buildConsoleTab(),
        ],
      ),
    );
  }

  Widget _buildIrisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModelInferenceCard(
            model: _irisModel,
            title: 'Iris Flower Species Classifier',
            description:
                'Runs local Python decision matrix directly from assets/models/iris_classifier.py',
            prediction: _irisPrediction,
            onPredictPressed: _runIrisPrediction,
            inputControls: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSlider('Sepal Length', _sepalLength, 4.0, 8.0,
                    (v) => setState(() => _sepalLength = v)),
                _buildSlider('Sepal Width', _sepalWidth, 2.0, 5.0,
                    (v) => setState(() => _sepalWidth = v)),
                _buildSlider('Petal Length', _petalLength, 1.0, 7.0,
                    (v) => setState(() => _petalLength = v)),
                _buildSlider('Petal Width', _petalWidth, 0.1, 2.5,
                    (v) => setState(() => _petalWidth = v)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PythonConsoleView(
              title: 'Iris Model Execution Stream', height: 160),
        ],
      ),
    );
  }

  Widget _buildHouseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModelInferenceCard(
            model: _houseModel,
            title: 'Real Estate Valuation Model',
            description:
                'Regression model estimating home values via assets/models/house_pricing.py',
            prediction: _housePrediction,
            onPredictPressed: _runHousePrediction,
            inputControls: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSlider('Square Footage', _sqft, 600, 5000,
                    (v) => setState(() => _sqft = v),
                    unit: ' sqft'),
                _buildSlider('Bedrooms', _bedrooms, 1, 6,
                    (v) => setState(() => _bedrooms = v),
                    divisions: 5),
                _buildSlider('Bathrooms', _bathrooms, 1, 5,
                    (v) => setState(() => _bathrooms = v),
                    divisions: 4),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PythonConsoleView(
              title: 'Regression Engine Stream', height: 160),
        ],
      ),
    );
  }

  Widget _buildSentimentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModelInferenceCard(
            model: _sentimentModel,
            title: 'Text Sentiment & Feature Extractor',
            description:
                'Extracts token polarities locally via assets/models/sentiment_nlp.py',
            prediction: _sentimentPrediction,
            onPredictPressed: _runSentimentPrediction,
            inputControls: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _sentimentTextController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Text Input for Sentiment Analysis',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PythonConsoleView(title: 'NLP Tokenizer Output', height: 160),
        ],
      ),
    );
  }

  Widget _buildConsoleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2436),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.code_rounded,
                        color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Direct Python Script Execution',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _rawCodeController,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Execute Python Directly'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _runRawPythonScript,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PythonConsoleView(
              title: 'Live Python Stderr & Stdout Terminal', height: 260),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String unit = '',
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(
              '${value.toStringAsFixed(divisions != null ? 0 : 1)}$unit',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFF6366F1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
