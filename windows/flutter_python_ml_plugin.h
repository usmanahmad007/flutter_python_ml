#ifndef FLUTTER_PLUGIN_FLUTTER_PYTHON_ML_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_PYTHON_ML_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_python_ml {

class FlutterPythonMlPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterPythonMlPlugin();

  virtual ~FlutterPythonMlPlugin();

  // Disallow copy and assign.
  FlutterPythonMlPlugin(const FlutterPythonMlPlugin&) = delete;
  FlutterPythonMlPlugin& operator=(const FlutterPythonMlPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_python_ml

#endif  // FLUTTER_PLUGIN_FLUTTER_PYTHON_ML_PLUGIN_H_
