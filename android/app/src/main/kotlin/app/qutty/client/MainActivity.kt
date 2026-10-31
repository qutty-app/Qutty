package app.qutty.client

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Starts and stops the foreground service that keeps the websocket open
        // in the background. The Dart side only ever asks; the service and its
        // isolate are owned by the platform so they survive this activity being
        // destroyed, which is the entire point of the transport.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "qutty/background_socket",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    MessageSocketService.start(applicationContext)
                    result.success(true)
                }
                "stop" -> {
                    MessageSocketService.stop(applicationContext)
                    result.success(true)
                }
                // Debug switch: ask Android for the background allowance the
                // foreground service needs, so the websocket can stay open while
                // the app is not in the foreground.
                "requestBackgroundUnlimited" -> {
                    requestBackgroundUnlimited(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestBackgroundUnlimited(context: Context) {
        // Android 13+ exposes the battery-optimization exemption as an intent;
        // asking for it is what lets a foreground service keep running while the
        // app is backgrounded without the platform pulling the plug.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val intent = Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            ).apply {
                data = Uri.parse("package:${context.packageName}")
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (t: Throwable) {
            // The gesture may be unavailable on this build or for this user; the
            // background socket is still worth starting, it just may not be
            // allowed to run freely.
            Log.e("MainActivity", "could not request background unlimited: ${t.message}")
        }
    }
}
