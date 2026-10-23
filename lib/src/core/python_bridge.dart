import 'dart:io';

import '../engine/base_engine.dart';
import '../engine/mock_engine.dart';
import '../engine/platform_engine.dart';
import '../engine/process_engine.dart';
import '../models/python_execution_result.dart';

/// The central coordinator bridging Flutter/Dart directly to on-device Python runtimes
/// and ML models without external web APIs or network overhead.
class PythonBridge {
  static final PythonBridge _instance = PythonBridge._internal();

  /// Shared singleton instance of [PythonBridge].
  static PythonBridge get instance => _instance;

  PythonEngine _engine;
  bool _initialized = false;

  PythonBridge({PythonEngine? engine})
      : _engine = engine ?? _createDefaultEngine();

  PythonBridge._internal() : _engine = _createDefaultEngine();

  /// Creates an appropriate default engine based on current platform capabilities.
  static PythonEngine _createDefaultEngine() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return PlatformChannelEngine();
      } else {
        return LocalProcessEngine();
      }
    } catch (_) {
      // In web or headless test environments without dart:io Platform support
      return MockPythonEngine();
    }
  }

  /// The active underlying Python execution engine.
  PythonEngine get engine => _engine;

  /// Swaps the active execution engine (e.g. switching to [MockPythonEngine] for testing).
  void setEngine(PythonEngine engine) {
    _engine = engine;
    _initialized = false;
  }

  /// Initializes the engine environment before first invocation.
  Future<void> initialize() async {
    if (_initialized) return;
    await _engine.initialize();
    _initialized = true;
  }

  /// Executes raw Python source code directly on device.
  Future<PythonExecutionResult> executeScript(
    String code, {
    Map<String, dynamic>? arguments,
  }) async {
    await initialize();
    return _engine.executeScript(code, arguments: arguments);
  }

  /// Executes a standalone `.py` file from disk or local assets.
  Future<PythonExecutionResult> executeFile(
    String filePath, {
    Map<String, dynamic>? arguments,
  }) async {
    await initialize();
    return _engine.executeFile(filePath, arguments: arguments);
  }

  /// Calls a designated function inside a Python script with arguments.
  Future<PythonExecutionResult> callFunction(
    String filePath,
    String functionName, {
    List<dynamic>? positionalArgs,
    Map<String, dynamic>? keywordArgs,
  }) async {
    await initialize();
    return _engine.callFunction(
      filePath,
      functionName,
      positionalArgs: positionalArgs,
      keywordArgs: keywordArgs,
    );
  }

  /// Real-time stream of standard output emitted by Python code.
  Stream<String> get stdout => _engine.stdoutStream;

  /// Real-time stream of standard error emitted by Python runtime.
  Stream<String> get stderr => _engine.stderrStream;

  /// Disposes active engine resources.
  Future<void> dispose() async {
    await _engine.dispose();
    _initialized = false;
  }
}
