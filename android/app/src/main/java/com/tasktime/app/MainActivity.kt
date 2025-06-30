package com.tasktime.app

import android.content.Intent
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"

    private lateinit var usageStatsModule: UsageStatsModule
    private lateinit var overlayModule: OverlayModule
    // Accessibility channels
    private lateinit var accessibilityMethodChannel: MethodChannel
    private lateinit var accessibilityEventChannel: EventChannel


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Configuring Flutter Engine and Platform Channels")

        // Initialize UsageStatsModule
        usageStatsModule = UsageStatsModule(applicationContext) { this }
        usageStatsModule.setupChannel(flutterEngine)

        // Initialize OverlayModule
        overlayModule = OverlayModule(applicationContext) { this }
        overlayModule.setupChannel(flutterEngine)

        // Initialize Accessibility Channels
        // Method Channel for Accessibility
        accessibilityMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MyAccessibilityService.METHOD_CHANNEL_NAME)
        accessibilityMethodChannel.setMethodCallHandler { call, result ->
            Log.d(TAG, "AccessibilityMethodChannel call: ${call.method}")
            when (call.method) {
                "requestAccessibilityPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        startActivity(intent)
                        result.success(true) // Indicates intent was sent
                    } catch (e: Exception) {
                        Log.e(TAG, "Error opening accessibility settings: ${e.message}", e)
                        result.error("ERROR_OPENING_SETTINGS", e.message, null)
                    }
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(MyAccessibilityService.isAccessibilityServiceEnabled(applicationContext))
                }
                else -> result.notImplemented()
            }
        }
        Log.d(TAG, "Accessibility Method Channel configured.")

        // Event Channel for Accessibility
        accessibilityEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, MyAccessibilityService.EVENT_CHANNEL_NAME)
        accessibilityEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "AccessibilityEventChannel onListen called. Sink: $events")
                    MyAccessibilityService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "AccessibilityEventChannel onCancel called.")
                    MyAccessibilityService.eventSink = null
                }
            }
        )
        Log.d(TAG, "Accessibility Event Channel configured.")

        // Initialize BackgroundService Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tasktime.app/background_service").setMethodCallHandler { call, result ->
            Log.d(TAG, "BackgroundServiceChannel call: ${call.method}")
            when (call.method) {
                "startService" -> {
                    val intent = Intent(applicationContext, BackgroundService::class.java).apply {
                        action = BackgroundService.ACTION_START_SERVICE
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        applicationContext.startForegroundService(intent)
                    } else {
                        applicationContext.startService(intent)
                    }
                    result.success("Background service started or intent sent.")
                }
                "stopService" -> {
                     val intent = Intent(applicationContext, BackgroundService::class.java).apply {
                        action = BackgroundService.ACTION_STOP_SERVICE
                    }
                    // Service can be stopped by sending an intent or calling context.stopService(intent)
                    // If it's a foreground service, it needs to call stopForeground() and stopSelf()
                    applicationContext.startService(intent) // Send intent to service to stop itself
                    result.success("Background service stop intent sent.")
                }
                "updateConfiguration" -> {
                    val scheduleArgs = call.argument<List<Map<String, Any>>>("schedule")
                    val blockedAppPackagesArgs = call.argument<List<String>>("blockedAppPackages")
                    val blockedWebsiteHostsArgs = call.argument<List<String>>("blockedWebsiteHosts")

                    Log.d(TAG, "Received updateConfiguration: Apps: $blockedAppPackagesArgs, Sites: $blockedWebsiteHostsArgs, Schedule Count: ${scheduleArgs?.size}")

                    val intent = Intent(applicationContext, BackgroundService::class.java).apply {
                        action = BackgroundService.ACTION_UPDATE_CONFIGURATION
                        // Need to convert List<Map> to ArrayList<HashMap> or Parcelable for Intent
                        if (scheduleArgs != null) {
                            val parcelableSchedule = ArrayList(scheduleArgs.map { HashMap(it) })
                            putSerializable("schedule", parcelableSchedule) // Using Serializable for simplicity
                        }
                        putStringArrayListExtra("blockedAppPackages", ArrayList(blockedAppPackagesArgs ?: listOf()))
                        putStringArrayListExtra("blockedWebsiteHosts", ArrayList(blockedWebsiteHostsArgs ?: listOf()))
                    }
                    applicationContext.startService(intent) // Send data to running service
                    result.success("Configuration update intent sent to service.")
                }
                // Add other methods like "getServiceStatus" if needed
                else -> result.notImplemented()
            }
        }
        Log.d(TAG, "BackgroundService Method Channel configured.")

        // Event Channel for Screen Time Updates from BackgroundService
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BackgroundService.EVENT_CHANNEL_SCREEN_TIME).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "ScreenTimeEventChannel onListen called.")
                    BackgroundService.screenTimeEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "ScreenTimeEventChannel onCancel called.")
                    BackgroundService.screenTimeEventSink = null
                }
            }
        )
        Log.d(TAG, "ScreenTime Event Channel configured.")
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        Log.d(TAG, "Cleaning up Flutter Engine and Platform Channels")
        usageStatsModule.tearDownChannel()
        overlayModule.tearDownChannel()
        accessibilityMethodChannel.setMethodCallHandler(null)
        accessibilityEventChannel.setStreamHandler(null)
        MyAccessibilityService.eventSink = null
        BackgroundService.screenTimeEventSink = null // Ensure sink is cleared
    }
}
