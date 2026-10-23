import '../models/python_execution_result.dart';

/// Contract for underlying Python execution engines (Process IPC, Platform Channel, Mock).
abstract class PythonEngine {
  /// Initializes the local Python environment.
  Future<void> initialize();

  /// Executes raw Python source code directly.
  Future<PythonExecutionResult> executeScript(
    String code, {
    Map<String, dynamic>? arguments,
  });

  /// Executes a Python file (`.py`) from local disk or assets.
  Future<PythonExecutionResult> executeFile(
    String filePath, {
    Map<String, dynamic>? arguments,
  });

  /// Calls a specific function inside a Python file with arguments.
  Future<PythonExecutionResult> callFunction(
    String filePath,
    String functionName, {
    List<dynamic>? positionalArgs,
    Map<String, dynamic>? keywordArgs,
  });

  /// Real-time stream of standard output from the Python environment.
  Stream<String> get stdoutStream;

  /// Real-time stream of standard error from the Python environment.
  Stream<String> get stderrStream;

  /// Releases resources held by the engine.
  Future<void> dispose();
}
