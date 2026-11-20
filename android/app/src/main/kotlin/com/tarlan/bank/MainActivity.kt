package com.tarlan.bank

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_protect_native")
        .setMethodCallHandler(
      MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
          // Native API: FLAG_SECURE blocks screenshots and screen recording.
          "enable" -> {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            result.success(true)
          }
          "disable" -> {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            result.success(true)
          }
          else -> {
            result.notImplemented()
          }
        }
      },
    )
  }
}