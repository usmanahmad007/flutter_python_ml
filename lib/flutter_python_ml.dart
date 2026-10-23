/// Production-ready on-device Machine Learning and direct Python execution bridge
/// for Flutter without external APIs or cloud network dependencies.
library flutter_python_ml;

export 'src/core/python_bridge.dart';
export 'src/core/python_ml_model.dart';
export 'src/engine/base_engine.dart';
export 'src/engine/mock_engine.dart';
export 'src/engine/platform_engine.dart';
export 'src/engine/process_engine.dart';
export 'src/models/ml_prediction.dart';
export 'src/models/python_execution_result.dart';
export 'src/models/tensor_data.dart';
export 'src/ui/model_inference_card.dart';
export 'src/ui/python_console_view.dart';
export 'src/ui/tensor_visualizer.dart';

import 'flutter_python_ml_platform_interface.dart';
import 'src/core/python_bridge.dart';
import 'src/models/python_execution_result.dart';

/// Legacy plugin class for platform info.
class FlutterPythonMl {
  Future<String?> getPlatformVersion() {
    return FlutterPythonMlPlatform.instance.getPlatformVersion();
  }
}

/// Top-level convenience API for quick Python script execution and ML invocation.
class PythonML {
  PythonML._();

  /// Executes raw Python code directly and returns the execution result.
  static Future<PythonExecutionResult> run(
    String code, {
    Map<String, dynamic>? arguments,
  }) {
    return PythonBridge.instance.executeScript(code, arguments: arguments);
  }

  /// Executes a local `.py` file.
  static Future<PythonExecutionResult> runFile(
    String filePath, {
    Map<String, dynamic>? arguments,
  }) {
    return PythonBridge.instance.executeFile(filePath, arguments: arguments);
  }

  /// Calls a function inside a Python file with positional and keyword arguments.
  static Future<PythonExecutionResult> call(
    String filePath,
    String functionName, {
    List<dynamic>? positionalArgs,
    Map<String, dynamic>? keywordArgs,
  }) {
    return PythonBridge.instance.callFunction(
      filePath,
      functionName,
      positionalArgs: positionalArgs,
      keywordArgs: keywordArgs,
    );
  }
}
