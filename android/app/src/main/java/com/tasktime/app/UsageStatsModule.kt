package com.tasktime.app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class UsageStatsModule(private val context: Context, private val activityProvider: () -> MainActivity?) {
    companion object {
        private const val CHANNEL_NAME = "com.tasktime.app/usage_stats"
        private const val TAG = "UsageStatsModule"
    }

    private var channel: MethodChannel? = null

    fun setupChannel(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "Method call received: ${call.method}")
            when (call.method) {
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(true) // Indicates intent was sent
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "getUsageStats" -> {
                    val intervalType = call.argument<String>("intervalType") ?: "daily" // "daily", "weekly", "monthly", or custom range
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()

                    if (!hasUsageStatsPermission()) {
                        Log.w(TAG, "getUsageStats called but permission is not granted.")
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted.", null)
                    } else {
                        Log.d(TAG, "getUsageStats called. IntervalType: $intervalType, StartTime: $startTime, EndTime: $endTime")
                        try {
                            val stats = getAppUsageStats(intervalType, startTime, endTime)
                            result.success(stats)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting usage stats: ${e.message}", e)
                            result.error("ERROR_FETCHING_STATS", "Failed to fetch usage stats: ${e.message}", null)
                        }
                    }
                }
                else -> {
                    Log.w(TAG, "Method ${call.method} not implemented")
                    result.notImplemented()
                }
            }
        }
        Log.d(TAG, "UsageStatsModule channel configured.")
    }

    fun tearDownChannel() {
        channel?.setMethodCallHandler(null)
        channel = null
        Log.d(TAG, "UsageStatsModule channel torn down.")
    }

    private fun getAppUsageStats(intervalTypeString: String, startTimeOverride: Long?, endTimeOverride: Long): Map<String, Long> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = java.util.Calendar.getInstance()
        val endTime = endTimeOverride
        var beginTime = startTimeOverride

        if (beginTime == null) { // Calculate beginTime based on intervalTypeString if not overridden
            when (intervalTypeString.lowercase()) {
                "daily" -> {
                    cal.timeInMillis = endTime
                    cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                    cal.set(java.util.Calendar.MINUTE, 0)
                    cal.set(java.util.Calendar.SECOND, 0)
                    cal.set(java.util.Calendar.MILLISECOND, 0)
                    beginTime = cal.timeInMillis
                }
                "weekly" -> {
                    cal.timeInMillis = endTime
                    cal.set(java.util.Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
                    cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                    cal.set(java.util.Calendar.MINUTE, 0)
                    cal.set(java.util.Calendar.SECOND, 0)
                    cal.set(java.util.Calendar.MILLISECOND, 0)
                    beginTime = cal.timeInMillis
                }
                "monthly" -> {
                    cal.timeInMillis = endTime
                    cal.set(java.util.Calendar.DAY_OF_MONTH, 1)
                    cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                    cal.set(java.util.Calendar.MINUTE, 0)
                    cal.set(java.util.Calendar.SECOND, 0)
                    cal.set(java.util.Calendar.MILLISECOND, 0)
                    beginTime = cal.timeInMillis
                }
                // "yearly" and "custom" would need more specific logic or rely on startTimeOverride
                else -> { // Default to daily if unknown, or could throw error
                    cal.timeInMillis = endTime
                    cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                    cal.set(java.util.Calendar.MINUTE, 0)
                    cal.set(java.util.Calendar.SECOND, 0)
                    cal.set(java.util.Calendar.MILLISECOND, 0)
                    beginTime = cal.timeInMillis
                    Log.w(TAG, "Unknown intervalType '$intervalTypeString', defaulting to daily.")
                }
            }
        }

        Log.d(TAG, "Querying usage stats from $beginTime to $endTime")

        // INTERVAL_DAILY is a constant for aggregation level, not the query range itself.
        // The queryUsageStats method returns data aggregated at the specified interval (daily, weekly, etc.)
        // that falls within the beginTime and endTime range.
        val usageStatsList = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, beginTime!!, endTime)

        val statsMap = mutableMapOf<String, Long>()
        for (usageStats in usageStatsList) {
            if (usageStats.totalTimeInForeground > 0) { // Only include apps that were used
                statsMap[usageStats.packageName] = (statsMap[usageStats.packageName] ?: 0L) + usageStats.totalTimeInForeground
                Log.d(TAG, "App: ${usageStats.packageName}, Time: ${usageStats.totalTimeInForeground}ms")
            }
        }
        Log.d(TAG, "Found ${statsMap.size} apps with usage.")
        return statsMap
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        val granted = mode == AppOpsManager.MODE_ALLOWED
        Log.d(TAG, "Usage stats permission granted: $granted")
        return granted
    }

    private fun requestUsageStatsPermission() {
        Log.d(TAG, "Requesting usage stats permission. Current activity: ${activityProvider()}")
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            // intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) // Not needed if started from activity
            activityProvider()?.startActivity(intent) ?: Log.e(TAG, "Activity is null, cannot start settings intent.")
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting usage stats permission: ${e.message}", e)
            // Fallback for environments where activity might not be available (e.g. background service)
            // Though permission requests should ideally be from UI context.
             try {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
             } catch (e2: Exception) {
                Log.e(TAG, "Error requesting usage stats permission with FLAG_ACTIVITY_NEW_TASK: ${e2.message}", e2)
             }
        }
    }
}
