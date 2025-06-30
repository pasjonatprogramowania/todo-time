package com.tasktime.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat // For NotificationCompat.Builder

// Assuming FlutterEngine interaction might be needed later, but not for initial setup
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.embedding.engine.dart.DartExecutor
// import io.flutter.plugin.common.MethodChannel

class BackgroundService : Service() {

    companion object {
        private const val TAG = "BackgroundService"
        private const val NOTIFICATION_CHANNEL_ID = "TaskTimeBackgroundServiceChannel"
        private const val NOTIFICATION_ID = 1888 // Arbitrary notification ID
        const val ACTION_START_SERVICE = "com.tasktime.app.action.START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.tasktime.app.action.STOP_SERVICE"
    }

    // private var flutterEngine: FlutterEngine? = null
    // private var methodChannel: MethodChannel? = null // For communication from service to Flutter if needed directly

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service onCreate")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())

        // Initialize Flutter engine if background Dart execution is needed.
        // For now, this service will primarily run native logic.
        // flutterEngine = FlutterEngine(this)
        // flutterEngine?.dartExecutor?.executeDartEntrypoint(
        //     DartExecutor.DartEntrypoint.createDefault() // Or a custom entrypoint
        // )
        // MethodChannel setup for service -> Flutter (if needed)
        // methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "com.tasktime.app/background_service_events")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "Service onStartCommand, Action: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_SERVICE -> {
                Log.i(TAG, "Starting monitoring logic...")
                // TODO: Implement actual monitoring logic in Step 10
                // This is where you'd start timers, register listeners, etc.
            }
            ACTION_STOP_SERVICE -> {
                Log.i(TAG, "Stopping service...")
                stopForeground(STOP_FOREGROUND_REMOVE) // For API 24+
                // stopForeground(true) // For older APIs (deprecated but common)
                stopSelf() // Stop the service
                return START_NOT_STICKY // Don't restart if stopped via explicit action
            }
            else -> {
                Log.w(TAG, "Received unknown or null action in onStartCommand.")
            }
        }

        // If the service is killed, try to restart it.
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "TaskTime Background Service",
                NotificationManager.IMPORTANCE_LOW // Low importance for less intrusive notification
            ).apply {
                description = "Channel for TaskTime background monitoring service."
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
            Log.d(TAG, "Notification channel created.")
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java) // Intent to open app on tap
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, pendingIntentFlags)

        // TODO: Replace R.mipmap.ic_launcher with a proper small icon for notifications
        // Ensure you have ic_stat_notification (monochrome) in your drawables for status bar.
        // For now, using app launcher icon which might not be ideal.
        val notificationIcon = R.mipmap.ic_launcher // Placeholder, should be a small monochrome icon

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("TaskTime Active")
            .setContentText("Monitoring app usage and tasks.")
            .setSmallIcon(notificationIcon) // Use a proper notification icon
            .setContentIntent(pendingIntent)
            .setOngoing(true) // Makes the notification non-dismissable by swipe
            .setPriority(NotificationCompat.PRIORITY_LOW) // Low priority
            .build()
    }


    override fun onBind(intent: Intent?): IBinder? {
        // We don't provide binding, so return null
        Log.d(TAG, "Service onBind called, returning null.")
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "Service onDestroy. Cleaning up...")
        // flutterEngine?.destroy()
        // flutterEngine = null
    }
}
