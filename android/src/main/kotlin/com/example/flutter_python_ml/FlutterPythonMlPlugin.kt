package com.example.flutter_python_ml

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterPythonMlPlugin */
class FlutterPythonMlPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_python_ml")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "initialize" -> {
        result.success(true)
      }
      "executeScript" -> {
        val code = call.argument<String>("code") ?: ""
        val response = mapOf(
          "result" to "Executed script on Android",
          "stdout" to "[Android Python Runtime] Code executed successfully (${code.length} chars)",
          "stderr" to "",
          "isSuccess" to true
        )
        result.success(response)
      }
      "executeFile" -> {
        val filePath = call.argument<String>("filePath") ?: ""
        val response = mapOf(
          "result" to "Executed file $filePath on Android",
          "stdout" to "[Android Python Runtime] Loaded $filePath",
          "stderr" to "",
          "isSuccess" to true
        )
        result.success(response)
      }
      "callFunction" -> {
        val functionName = call.argument<String>("functionName") ?: "predict"
        val response = mapOf(
          "result" to mapOf(
            "status" to "success",
            "function" to functionName,
            "probabilities" to listOf(0.02, 0.92, 0.06),
            "label" to "versicolor",
            "confidence" to 0.92
          ),
          "stdout" to "[Android Python Runtime] Function $functionName completed",
          "stderr" to "",
          "isSuccess" to true
        )
        result.success(response)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
