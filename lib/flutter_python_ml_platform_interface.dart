import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_python_ml_method_channel.dart';

abstract class FlutterPythonMlPlatform extends PlatformInterface {
  /// Constructs a FlutterPythonMlPlatform.
  FlutterPythonMlPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterPythonMlPlatform _instance = MethodChannelFlutterPythonMl();

  /// The default instance of [FlutterPythonMlPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterPythonMl].
  static FlutterPythonMlPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterPythonMlPlatform] when
  /// they register themselves.
  static set instance(FlutterPythonMlPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
