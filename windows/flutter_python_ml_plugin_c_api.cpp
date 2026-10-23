#include "include/flutter_python_ml/flutter_python_ml_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_python_ml_plugin.h"

void FlutterPythonMlPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_python_ml::FlutterPythonMlPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
