import 'dart:async';
import 'package:flutter/services.dart';

import '../models/python_execution_result.dart';
import 'base_engine.dart';

/// Platform channel engine communicating with native Android and iOS runners.
class PlatformChannelEngine implements PythonEngine {
  final MethodChannel _channel = const MethodChannel('flutter_python_ml');
  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get stdoutStream => _stdoutController.stream;

  @override
  Stream<String> get stderrStream => _stderrController.stream;

  @override
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } catch (_) {
      // Ignored if platform does not require explicit initialization
    }
  }

  @override
  Future<PythonExecutionResult> executeScript(
    String code, {
    Map<String, dynamic>? arguments,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final res = await _channel.invokeMethod<Map>('executeScript', {
        'code': code,
        'arguments': arguments ?? {},
      });
      stopwatch.stop();

      final map = res != null ? Map<String, dynamic>.from(res) : {};
      final stdout = map['stdout'] as String? ?? '';
      final stderr = map['stderr'] as String? ?? '';
      final isSuccess = map['isSuccess'] as bool? ?? true;
      final errorTrace = map['errorTrace'] as String?;

      if (stdout.isNotEmpty) _stdoutController.add(stdout);
      if (stderr.isNotEmpty) _stderrController.add(stderr);

      if (!isSuccess) {
        return PythonExecutionResult.failure(
          errorTrace: errorTrace ?? 'Execution failed on platform',
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed,
        );
      }

      return PythonExecutionResult.success(
        result: map['result'],
        stdout: stdout,
        stderr: stderr,
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
    final stopwatch = Stopwatch()..start();
    try {
      final res = await _channel.invokeMethod<Map>('executeFile', {
        'filePath': filePath,
        'arguments': arguments ?? {},
      });
      stopwatch.stop();

      final map = res != null ? Map<String, dynamic>.from(res) : {};
      final stdout = map['stdout'] as String? ?? '';
      final stderr = map['stderr'] as String? ?? '';
      final isSuccess = map['isSuccess'] as bool? ?? true;
      final errorTrace = map['errorTrace'] as String?;

      if (!isSuccess) {
        return PythonExecutionResult.failure(
          errorTrace: errorTrace ?? 'Execution failed on platform',
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed,
        );
      }

      return PythonExecutionResult.success(
        result: map['result'],
        stdout: stdout,
        stderr: stderr,
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
  Future<PythonExecutionResult> callFunction(
    String filePath,
    String functionName, {
    List<dynamic>? positionalArgs,
    Map<String, dynamic>? keywordArgs,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final res = await _channel.invokeMethod<Map>('callFunction', {
        'filePath': filePath,
        'functionName': functionName,
        'positionalArgs': positionalArgs ?? [],
        'keywordArgs': keywordArgs ?? {},
      });
      stopwatch.stop();

      final map = res != null ? Map<String, dynamic>.from(res) : {};
      final stdout = map['stdout'] as String? ?? '';
      final stderr = map['stderr'] as String? ?? '';
      final isSuccess = map['isSuccess'] as bool? ?? true;
      final errorTrace = map['errorTrace'] as String?;

      if (!isSuccess) {
        return PythonExecutionResult.failure(
          errorTrace: errorTrace ?? 'Function call failed on platform',
          stdout: stdout,
          stderr: stderr,
          duration: stopwatch.elapsed,
        );
      }

      return PythonExecutionResult.success(
        result: map['result'],
        stdout: stdout,
        stderr: stderr,
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
