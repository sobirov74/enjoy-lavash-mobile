package com.aurumdev.enjoy_lavash_mobile

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "enjoy_lavash_mobile/external_url"
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.arguments as? String
            if (url.isNullOrBlank()) {
                result.success(false)
                return@setMethodCallHandler
            }

            // Only web links leave the app. Dart validates first; this is the
            // last line of defence against custom schemes (intent:, file:, tel:).
            val uri = Uri.parse(url)
            if (!uri.scheme.equals("https", ignoreCase = true) || uri.host.isNullOrBlank()) {
                result.success(false)
                return@setMethodCallHandler
            }

            try {
                val intent = Intent(Intent.ACTION_VIEW, uri)
                startActivity(intent)
                result.success(true)
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }
}
