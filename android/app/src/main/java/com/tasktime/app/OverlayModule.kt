package com.tasktime.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class OverlayModule(private val context: Context, private val activityProvider: () -> MainActivity?) {
    companion object {
        private const val CHANNEL_NAME = "com.tasktime.app/overlay"
        private const val TAG = "OverlayModule"
    }

    private var channel: MethodChannel? = null

    fun setupChannel(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "Method call received: ${call.method}")
            when (call.method) {
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true) // Indicates intent was sent
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "showOverlay" -> {
                    if (hasOverlayPermission()) {
                        Log.d(TAG, "showOverlay called. Attempting to start LockScreenActivity.")
                        val intent = Intent(context, LockScreenActivity::class.java)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP) // Ensure only one instance if already shown
                        intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY) // Don't keep it in history stack
                        // intent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS) // Keep it out of recents
                        context.startActivity(intent)
                        result.success(true)
                    } else {
                        Log.w(TAG, "showOverlay called, but no overlay permission.")
                        result.error("NO_PERMISSION", "Overlay permission not granted.", null)
                    }
                }
                "hideOverlay" -> {
                    // Hiding is typically done by the LockScreenActivity itself finishing,
                    // or by sending a broadcast intent that LockScreenActivity listens for.
                    // For now, we'll assume LockScreenActivity has a way to be finished.
                    // This could also involve a static method in LockScreenActivity to finish itself.
                    Log.d(TAG, "hideOverlay called. Broadcasting intent to close lock screen.")
                    val intent = Intent(LockScreenActivity.ACTION_CLOSE_LOCK_SCREEN)
                    context.sendBroadcast(intent)
                    result.success(true)
                }
                else -> {
                    Log.w(TAG, "Method ${call.method} not implemented")
                    result.notImplemented()
                }
            }
        }
        Log.d(TAG, "OverlayModule channel configured.")
    }

     fun tearDownChannel() {
        channel?.setMethodCallHandler(null)
        channel = null
        Log.d(TAG, "OverlayModule channel torn down.")
    }

    private fun hasOverlayPermission(): Boolean {
        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true // Below M, permission is granted by default if declared in manifest (though SYSTEM_ALERT_WINDOW is protection level dangerous pre-M)
        }
        Log.d(TAG, "Overlay permission granted: $granted")
        return granted
    }

    private fun requestOverlayPermission() {
        Log.d(TAG, "Requesting overlay permission. Current activity: ${activityProvider()}")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(context)) {
                try {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${context.packageName}")
                    )
                    // intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) // Not needed if started from activity
                    activityProvider()?.startActivity(intent) ?: Log.e(TAG, "Activity is null, cannot start settings intent.")
                } catch (e: Exception) {
                    Log.e(TAG, "Error requesting overlay permission: ${e.message}", e)
                     try {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${context.packageName}")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                     } catch (e2: Exception) {
                        Log.e(TAG, "Error requesting overlay permission with FLAG_ACTIVITY_NEW_TASK: ${e2.message}", e2)
                     }
                }
            } else {
                 Log.d(TAG, "Overlay permission already granted.")
            }
        } else {
            Log.d(TAG, "Overlay permission not needed to request for SDK < M.")
        }
    }
}
