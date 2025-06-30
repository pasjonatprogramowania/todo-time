package com.tasktime.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.pm.ServiceInfo
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MyAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "MyAccessibilityService"
        private const val METHOD_CHANNEL_NAME = "com.tasktime.app/accessibility_methods"
        private const val EVENT_CHANNEL_NAME = "com.tasktime.app/accessibility_events"

        var eventSink: EventChannel.EventSink? = null // For EventChannel

        // Method to check if the service is enabled
        // This is called from Flutter via MethodChannel
        fun isAccessibilityServiceEnabled(context: Context): Boolean {
            val expectedComponentName = context.packageName + "/.MyAccessibilityService"
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            val isEnabled = enabledServices?.contains(expectedComponentName) == true
            Log.d(TAG, "Accessibility Service enabled: $isEnabled (Expected: $expectedComponentName, Enabled: $enabledServices)")
            return isEnabled
        }
    }

    private var methodChannel: MethodChannel? = null
    // EventChannel setup is typically done in MainActivity or Application class where FlutterEngine is available.
    // However, the service itself will send events.

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "Accessibility Service connected.")
        // Configure the service
        val info = AccessibilityServiceInfo().apply {
            // Set the type of events an accessibility service wants to listen to.
            // TYPE_WINDOW_STATE_CHANGED is crucial for detecting foreground app changes.
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED // | AccessibilityEvent.TYPE_WINDOWS_CHANGED
            // Set the feedback type of the service.
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC // Or FEEDBACK_VISUAL, FEEDBACK_SPOKEN etc.
            // Default services are invoked only if no package specific service is preceding it.
            // flags = AccessibilityServiceInfo.DEFAULT; (DEPRECATED)
            // Use FLAG_REPORT_VIEW_IDS to get view IDs if needed.
            // flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
            // Set the timeout for the service.
            notificationTimeout = 100 // Milliseconds
            // Configure package names to listen to, null for all apps.
            // packageNames = arrayOf("com.example.app1", "com.example.app2") // Example
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR2) {
            // For API 18+
            info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                         AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS // If needed
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            // For API 21+
             info.flags = info.flags or ServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
        }


        this.serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Log.d(TAG, "onAccessibilityEvent: ${event?.toString()}")
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            val className = event.className?.toString()
            Log.d(TAG, "Foreground app changed: $packageName / $className")
            if (packageName != null) {
                eventSink?.success(packageName) // Send package name to Flutter via EventChannel
            }
        }
        // Handle other event types if necessary
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service interrupted.")
        // Called when the system wants to interrupt the feedback this service is providing.
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.w(TAG, "Accessibility Service destroyed.")
        eventSink = null // Clean up
        methodChannel?.setMethodCallHandler(null)
    }

    // This method is for setting up the MethodChannel from MainActivity
    // It's a bit unconventional for the service to host its own MethodChannel like this
    // usually the channel is set up in MainActivity and calls methods on a service instance or companion object.
    // However, for the "isServiceEnabled" check that Flutter calls, it's simpler if MainActivity handles it.
    // The requestPermission will also be handled in MainActivity as it needs to launch an Intent.
}

// MethodChannel setup for AccessibilityService will be in MainActivity
// It will call static methods on MyAccessibilityService or manage an instance.
// EventChannel setup will also be in MainActivity.
