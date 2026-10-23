import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/python_execution_result.dart';
import 'base_engine.dart';

/// Zero-network local process engine that executes Python scripts and calls functions
/// directly on device using standard I/O stream IPC.
class LocalProcessEngine implements PythonEngine {
  /// The Python executable name or full path (e.g. `python3`, `python`).
  final String pythonExecutable;

  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();

  bool _initialized = false;

  LocalProcessEngine({
    this.pythonExecutable = 'python3',
  });

  @override
  Stream<String> get stdoutStream => _stdoutController.stream;

  @override
  Stream<String> get stderrStream => _stderrController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final res = await Process.run(pythonExecutable, ['--version']);
      if (res.exitCode == 0) {
        _initialized = true;
      } else {
        // Fallback to 'python' if 'python3' is not linked
        final fallback = await Process.run('python', ['--version']);
        if (fallback.exitCode == 0) {
          _initialized = true;
        }
      }
    } catch (_) {
      // Allow lazy initialization on first execution
      _initialized = true;
    }
  }

  @override
  Future<PythonExecutionResult> executeScript(
    String code, {
    Map<String, dynamic>? arguments,
  }) async {
    final stopwatch = Stopwatch()..start();
    final argsJson = jsonEncode(arguments ?? {});

    // Embedded harness that injects arguments, captures prints, and outputs result
    final harness = '''
import sys, json

__args__ = json.loads(${jsonEncode(argsJson)})

try:
$code
except Exception as e:
    import traceback
    sys.stderr.write(traceback.format_exc())
    sys.exit(1)
''';

    try {
      final process = await Process.start(pythonExecutable, ['-c', harness]);
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      process.stdout.transform(utf8.decoder).listen((data) {
        stdoutBuffer.write(data);
        _stdoutController.add(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
        _stderrController.add(data);
      });

      final exitCode = await process.exitCode;
      stopwatch.stop();

      final outStr = stdoutBuffer.toString().trim();
      final errStr = stderrBuffer.toString().trim();

      if (exitCode != 0) {
        return PythonExecutionResult.failure(
          errorTrace:
              errStr.isNotEmpty ? errStr : 'Process exited with code $exitCode',
          stdout: outStr,
          stderr: errStr,
          duration: stopwatch.elapsed,
        );
      }

      // Attempt to decode JSON output if emitted
      dynamic parsedResult = outStr;
      try {
        parsedResult = jsonDecode(outStr);
      } catch (_) {}

      return PythonExecutionResult.success(
        result: parsedResult,
        stdout: outStr,
        stderr: errStr,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return PythonExecutionResult.failure(
        errorTrace: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  Future<PythonExecutionResult> executeFile(
    String filePath, {
    Map<String, dynamic>? arguments,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return PythonExecutionResult.failure(
        errorTrace: 'Python file not found at: $filePath',
        duration: Duration.zero,
      );
    }
    final content = await file.readAsString();
    return executeScript(content, arguments: arguments);
  }

  @override
  Future<PythonExecutionResult> callFunction(
    String filePath,
    String functionName, {
    List<dynamic>? positionalArgs,
    Map<String, dynamic>? keywordArgs,
  }) async {
    final stopwatch = Stopwatch()..start();
    final file = File(filePath);
    if (!await file.exists()) {
      return PythonExecutionResult.failure(
        errorTrace: 'Python file not found at: $filePath',
        duration: Duration.zero,
      );
    }

    final posJson = jsonEncode(positionalArgs ?? []);
    final kwJson = jsonEncode(keywordArgs ?? {});

    // Dynamic Module Loader Harness
    final harness = '''
import sys, os, json, importlib.util, traceback

file_path = r"""$filePath"""
func_name = "$functionName"
pos_args = json.loads("""$posJson""")
kw_args = json.loads("""$kwJson""")

module_name = os.path.splitext(os.path.basename(file_path))[0]
spec = importlib.util.spec_from_file_location(module_name, file_path)
if spec is None or spec.loader is None:
    sys.stderr.write(f"Could not load module from {file_path}\\n")
    sys.exit(1)

module = importlib.util.module_from_spec(spec)
sys.modules[module_name] = module

try:
    spec.loader.exec_module(module)
except Exception:
    sys.stderr.write(traceback.format_exc())
    sys.exit(1)

if not hasattr(module, func_name):
    sys.stderr.write(f"Function '{func_name}' not found in {file_path}\\n")
    sys.exit(1)

func = getattr(module, func_name)

try:
    if kw_args and pos_args:
        result = func(*pos_args, **kw_args)
    elif kw_args:
        result = func(**kw_args)
    elif pos_args:
        result = func(*pos_args)
    else:
        result = func()
    
    # Delimited JSON serialization for clean output capture
    print("---RESULT_START---")
    print(json.dumps(result))
    print("---RESULT_END---")
except Exception:
    sys.stderr.write(traceback.format_exc())
    sys.exit(1)
''';

    try {
      final process = await Process.start(pythonExecutable, ['-c', harness]);
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      process.stdout.transform(utf8.decoder).listen((data) {
        stdoutBuffer.write(data);
        _stdoutController.add(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
        _stderrController.add(data);
      });

      final exitCode = await process.exitCode;
      stopwatch.stop();

      final outStr = stdoutBuffer.toString();
      final errStr = stderrBuffer.toString().trim();

      if (exitCode != 0) {
        return PythonExecutionResult.failure(
          errorTrace:
              errStr.isNotEmpty ? errStr : 'Process exited with code $exitCode',
          stdout: outStr,
          stderr: errStr,
          duration: stopwatch.elapsed,
        );
      }

      // Extract delimited JSON result
      dynamic parsedResult;
      const startTag = '---RESULT_START---';
      const endTag = '---RESULT_END---';

      if (outStr.contains(startTag) && outStr.contains(endTag)) {
        final startIdx = outStr.indexOf(startTag) + startTag.length;
        final endIdx = outStr.indexOf(endTag, startIdx);
        final rawJson = outStr.substring(startIdx, endIdx).trim();
        try {
          parsedResult = jsonDecode(rawJson);
        } catch (_) {
          parsedResult = rawJson;
        }
      } else {
        parsedResult = outStr.trim();
      }

      return PythonExecutionResult.success(
        result: parsedResult,
        stdout: outStr.trim(),
        stderr: errStr,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return PythonExecutionResult.failure(
        errorTrace: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _stdoutController.close();
    await _stderrController.close();
  }
}
