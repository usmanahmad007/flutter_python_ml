import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_python_ml_platform_interface.dart';

/// An implementation of [FlutterPythonMlPlatform] that uses method channels.
class MethodChannelFlutterPythonMl extends FlutterPythonMlPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_python_ml');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
