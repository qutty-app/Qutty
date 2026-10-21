package app.qutty.client

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
                else -> result.notImplemented()
            }
        }
    }
}
