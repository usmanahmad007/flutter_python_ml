/// Encapsulates the execution outcome of running a local Python script or function.
class PythonExecutionResult {
  /// The returned data from the Python function or script.
  final dynamic result;

  /// Standard output emitted by the Python script (e.g. `print()` statements).
  final String stdout;

  /// Standard error output emitted by Python runtime or warnings.
  final String stderr;

  /// Total execution duration.
  final Duration duration;

  /// Whether the script completed without unhandled exceptions.
  final bool isSuccess;

  /// Detailed Python traceback if an exception occurred.
  final String? errorTrace;

  const PythonExecutionResult({
    required this.result,
    this.stdout = '',
    this.stderr = '',
    required this.duration,
    this.isSuccess = true,
    this.errorTrace,
  });

  /// Convenience factory for a successful execution.
  factory PythonExecutionResult.success({
    required dynamic result,
    String stdout = '',
    String stderr = '',
    required Duration duration,
  }) =>
      PythonExecutionResult(
        result: result,
        stdout: stdout,
        stderr: stderr,
        duration: duration,
        isSuccess: true,
      );

  /// Convenience factory for a failed execution.
  factory PythonExecutionResult.failure({
    required String errorTrace,
    String stdout = '',
    String stderr = '',
    required Duration duration,
    dynamic fallbackResult,
  }) =>
      PythonExecutionResult(
        result: fallbackResult,
        stdout: stdout,
        stderr: stderr,
        duration: duration,
        isSuccess: false,
        errorTrace: errorTrace,
      );

  Map<String, dynamic> toJson() => {
        'result': result,
        'stdout': stdout,
        'stderr': stderr,
        'durationMs': duration.inMicroseconds / 1000.0,
        'isSuccess': isSuccess,
        if (errorTrace != null) 'errorTrace': errorTrace,
      };

  @override
  String toString() {
    return 'PythonExecutionResult(success: $isSuccess, duration: ${duration.inMilliseconds}ms)';
  }
}

/// Thrown when an unhandled Python exception or syntax error occurs.
class PythonExecutionException implements Exception {
  final String message;
  final String? traceback;
  final int exitCode;

  const PythonExecutionException(
    this.message, {
    this.traceback,
    this.exitCode = 1,
  });

  @override
  String toString() {
    if (traceback != null && traceback!.isNotEmpty) {
      return 'PythonExecutionException: $message\n--- Python Traceback ---\n$traceback';
    }
    return 'PythonExecutionException: $message (exitCode: $exitCode)';
  }
}
