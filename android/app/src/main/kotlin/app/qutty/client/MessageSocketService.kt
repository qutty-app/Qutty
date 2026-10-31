package app.qutty.client

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Keeps a websocket open while the app is not in the foreground.
 *
 * This is the transport that works for every build. FCM needs the app registered
 * in one specific Firebase project, so a build with a different application id or
 * signature has no FCM token at all; a socket only needs the server the user is
 * already signed in to.
 *
 * Android does not allow a background network connection without a foreground
 * service, so this runs as one. The cost is a permanent, low-importance
 * notification plus the battery cost of a live connection, which is the trade
 * for delivery that does not depend on Google.
 *
 * Two platform limits are worth knowing about rather than discovering in
 * production. Android 13+ requires POST_NOTIFICATIONS for the service
 * notification to be visible at all, and the service is refused without it. And
 * Android 15 caps dataSync foreground services at roughly six hours per day, so
 * this is a best-effort transport, not a guarantee -- the same class of
 * guarantee FCM gives, which is why the picker defaults to FCM when it exists.
 *
 * The debug "keep websocket alive" switch asks for the background allowance the
 * service needs through the same channel; that is what
 * `requestBackgroundUnlimited` on the Dart side is for.
 */
class MessageSocketService : Service() {
    private var engine: FlutterEngine? = null
    private var starting = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Promote before any slow initialisation: Android gives a service a
        // few seconds to call startForeground, and a cold Flutter loader start
        // can outlast that, which crashes with ForegroundServiceDidNotStart.
        promoteToForeground()

        if (engine == null) {
            startIsolate()
        }

        // START_STICKY so the system restores the connection after a low-memory
        // kill, which is the normal end of a long-lived socket.
        return START_STICKY
    }

    private fun startIsolate() {
        if (starting) {
            return
        }
        starting = true
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationCompleteAsync(
            applicationContext,
            null,
            // A Handler rather than Context.getMainExecutor(), which needs API 28
            // and would raise the service's minSdk.
            Handler(Looper.getMainLooper()),
            // The fourth argument is a plain Runnable: it runs once the loader
            // has finished, and there is no failure callback, so a start that
            // goes wrong is caught around the engine creation instead.
            object : Runnable {
                override fun run() {
                    starting = false
                    try {
                        val created = FlutterEngine(applicationContext)
                        engine = created

                        // The isolate runs headless with no activity behind it, so
                        // it cannot reach MainActivity's channel. Registering the
                        // same channel on this engine lets the isolate shut its own
                        // service down when it decides it has nothing to listen to,
                        // rather than leaving a foreground notification behind a
                        // connection that already went away.
                        MethodChannel(
                            created.dartExecutor.binaryMessenger,
                            BACKGROUND_SOCKET_CHANNEL,
                        ).setMethodCallHandler { call, _ ->
                            when (call.method) {
                                "stop" -> stopSelf()
                                "start" -> Unit
                                else -> Unit
                            }
                        }

                        created.dartExecutor.executeDartEntrypoint(
                            DartExecutor.DartEntrypoint(
                                loader.findAppBundlePath(),
                                BACKGROUND_ENTRYPOINT,
                            ),
                        )
                    } catch (t: Throwable) {
                        Log.e(TAG, "could not start the background isolate: ${t.message}")
                        // Nothing will ever arrive on a connection that could not
                        // start, so do not keep a foreground notification for it.
                        stopSelf()
                    }
                }
            },
        )
    }

    /**
     * Shows the ongoing notification the OS requires to keep this service, and
     * which doubles as the way the user can see the app is connected.
     */
    private fun promoteToForeground() {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CONNECTION_CHANNEL_ID,
                "Background connection",
                // Minimal importance, and a minimal-importance channel has no
                // sound and no heads-up. This notification is infrastructure:
                // a user should see it, not be interrupted by it.
                NotificationManager.IMPORTANCE_MIN,
            )
            channel.setShowBadge(false)
            manager.createNotificationChannel(channel)
        }

        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = launch?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CONNECTION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setContentTitle("Qutty is connected")
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setOngoing(true)
        if (pendingIntent != null) {
            builder.setContentIntent(pendingIntent)
        }

        startForeground(NOTIFICATION_ID, builder.build())
    }

    override fun onDestroy() {
        // Destroying the engine tears down the isolate, and with it the socket,
        // rather than leaving an orphaned connection behind a dead service.
        engine?.destroy()
        engine = null
        super.onDestroy()
    }

    companion object {
        private const val TAG = "MessageSocketService"
        private const val CONNECTION_CHANNEL_ID = "qutty_connection"
        private const val NOTIFICATION_ID = 1001

        /**
         * Must match the entrypoint in `background_socket.dart`. It has to be
         * tree-shake annotated there, or a release build strips it and the
         * service connects to nothing.
         */
        private const val BACKGROUND_ENTRYPOINT =
            "package:qutty/services/background_socket.dart"

        /** Shared by the activity channel and the background engine's own. */
        const val BACKGROUND_SOCKET_CHANNEL = "qutty/background_socket"

        /** Starts the background socket, replacing any existing connection. */
        fun start(context: Context) {
            val intent = Intent(context, MessageSocketService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /** Stops the background socket if it is running. */
        fun stop(context: Context) {
            context.stopService(Intent(context, MessageSocketService::class.java))
        }
    }
}
