package com.tasktime.app

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
import androidx.core.app.NotificationCompat
import java.util.Calendar // For time checking
import java.util.Timer
import java.util.TimerTask

class BackgroundService : Service() {

    companion object {
        private const val TAG = "BackgroundService"
        private const val NOTIFICATION_CHANNEL_ID = "TaskTimeBackgroundServiceChannel"
        private const val NOTIFICATION_ID = 1888
        const val ACTION_START_SERVICE = "com.tasktime.app.action.START_SERVICE"
        const val ACTION_STOP_SERVICE = "com.tasktime.app.action.STOP_SERVICE"
        const val ACTION_UPDATE_CONFIGURATION = "com.tasktime.app.action.UPDATE_CONFIGURATION"
        const val ACTION_UPDATE_FOREGROUND_APP = "com.tasktime.app.action.UPDATE_FOREGROUND_APP"
        const val ACTION_UPDATE_SCREEN_TIME = "com.tasktime.app.action.UPDATE_SCREEN_TIME"

        const val EXTRA_SCHEDULE = "schedule" // List<Map<String, Any>>
        const val EXTRA_BLOCKED_APP_PACKAGES = "blockedAppPackages" // List<String>
        const val EXTRA_BLOCKED_WEBSITE_HOSTS = "blockedWebsiteHosts" // List<String>
        const val EXTRA_FOREGROUND_APP_PACKAGE = "foregroundAppPackage" // String
        const val EXTRA_FOREGROUND_APP_CLASS = "foregroundAppClass" // String
        const val EXTRA_EARNED_SCREEN_TIME_MS = "earnedScreenTimeMs" // Long

        // For EventChannel to Flutter (for screen time updates)
        const val EVENT_CHANNEL_SCREEN_TIME = "com.tasktime.app/screen_time_events"
        var screenTimeEventSink: io.flutter.plugin.common.EventChannel.EventSink? = null
    }

    private var currentSchedule: List<Map<String, Any>> = listOf()
    private var blockedAppPackages: List<String> = listOf()
    private var blockedWebsiteHosts: List<String> = listOf() // Not yet used in logic, but ready
    private var currentForegroundAppPackage: String? = null
    private var earnedScreenTimeMs: Long = 0L

    private var screenTimeDeductionTimer: Timer? = null
    private var currentlyTrackedAppPackageForDeduction: String? = null
    private val handler = Handler(Looper.getMainLooper())

    private var lastResetCheckDate: Calendar? = null
    private var dailyResetTimer: Timer? = null


    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service onCreate")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        scheduleDailyResetCheck()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "Service onStartCommand, Action: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_SERVICE -> {
                Log.i(TAG, "Service explicitly started. Will evaluate state if data available.")
                // If config is already present, evaluate. Otherwise, wait for ACTION_UPDATE_CONFIGURATION.
                if (currentSchedule.isNotEmpty() || blockedAppPackages.isNotEmpty()) {
                     evaluateCurrentState()
                } else {
                    Log.i(TAG, "No configuration yet, waiting for update.")
                }
            }
            ACTION_STOP_SERVICE -> {
                Log.i(TAG, "Stopping service...")
                stopScreenTimeDeductionTimer()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE_CONFIGURATION -> {
                Log.d(TAG, "Received ACTION_UPDATE_CONFIGURATION")
                val serializableSchedule = intent.getSerializableExtra(EXTRA_SCHEDULE)
                if (serializableSchedule is ArrayList<*>) {
                    @Suppress("UNCHECKED_CAST")
                    currentSchedule = serializableSchedule as ArrayList<Map<String, Any>>
                    Log.d(TAG, "Updated schedule: ${currentSchedule.size} entries")
                }
                intent.getStringArrayListExtra(EXTRA_BLOCKED_APP_PACKAGES)?.let {
                    blockedAppPackages = it
                    Log.d(TAG, "Updated blocked apps: $blockedAppPackages")
                }
                intent.getStringArrayListExtra(EXTRA_BLOCKED_WEBSITE_HOSTS)?.let {
                    blockedWebsiteHosts = it
                    Log.d(TAG, "Updated blocked websites: $blockedWebsiteHosts")
                }
                evaluateCurrentState()
            }
            ACTION_UPDATE_FOREGROUND_APP -> {
                val oldForegroundApp = currentForegroundAppPackage
                currentForegroundAppPackage = intent.getStringExtra(EXTRA_FOREGROUND_APP_PACKAGE)
                Log.d(TAG, "Foreground app updated: $currentForegroundAppPackage (was $oldForegroundApp)")
                if (oldForegroundApp != currentForegroundAppPackage) { // Only evaluate if it actually changed
                    evaluateCurrentState()
                }
            }
            ACTION_UPDATE_SCREEN_TIME -> {
                earnedScreenTimeMs = intent.getLongExtra(EXTRA_EARNED_SCREEN_TIME_MS, 0L)
                Log.d(TAG, "Earned screen time updated: $earnedScreenTimeMs ms")
                sendScreenTimeUpdateToFlutter(earnedScreenTimeMs) // Inform Flutter immediately
                evaluateCurrentState()
            }
            else -> {
                Log.w(TAG, "Received unknown or null action: ${intent?.action}. Service might be restarting.")
                if (currentSchedule.isNotEmpty() || blockedAppPackages.isNotEmpty()) {
                    evaluateCurrentState()
                }
            }
        }
        return START_STICKY
    }

    private fun evaluateCurrentState() {
        val localCurrentForegroundApp = currentForegroundAppPackage
        Log.d(TAG, "Evaluating current state. Foreground: $localCurrentForegroundApp, ScreenTime: $earnedScreenTimeMs ms, Schedule entries: ${currentSchedule.size}, Blocked apps: ${blockedAppPackages.size}")

        if (localCurrentForegroundApp == null) {
            Log.d(TAG, "No known foreground app. Stopping deduction if active.")
            stopScreenTimeDeductionTimer() // Stop deduction if no foreground app is known
            // No need to hide lock screen here as it's context-less.
            return
        }

        val isAppOnBlockList = isAppCurrentlyBlocked(localCurrentForegroundApp)
        val isTimeInScheduledBlock = isCurrentTimeInScheduledBlock()

        Log.d(TAG, "App: $localCurrentForegroundApp, IsOnBlockList: $isAppOnBlockList, IsTimeInScheduledBlock: $isTimeInScheduledBlock")

        if (isAppOnBlockList && isTimeInScheduledBlock) {
            if (earnedScreenTimeMs > 0) {
                Log.d(TAG, "$localCurrentForegroundApp is blocked by schedule, screen time available ($earnedScreenTimeMs ms). Starting deduction.")
                hideLockScreen()
                startScreenTimeDeduction(localCurrentForegroundApp)
            } else {
                Log.d(TAG, "$localCurrentForegroundApp is blocked by schedule, no screen time. Showing lock screen.")
                stopScreenTimeDeductionTimer()
                showLockScreen()
            }
        } else {
            Log.d(TAG, "$localCurrentForegroundApp not subject to blocking now. Ensuring no active block/deduction.")
            hideLockScreen() // If it was shown for this app for some reason
            stopScreenTimeDeductionTimer() // Stop deduction if it was for this app or any app
        }
    }

    private fun isAppCurrentlyBlocked(packageName: String): Boolean {
        // TODO: Handle website blocking if packageName is a browser. This needs URL info.
        // For now, only app package blocking.
        val isBlocked = blockedAppPackages.contains(packageName)
        Log.d(TAG, "Checking if $packageName is blocked: $isBlocked (List: $blockedAppPackages)")
        return isBlocked
    }

    private fun isCurrentTimeInScheduledBlock(): Boolean {
        if (currentSchedule.isEmpty()) {
            Log.d(TAG, "No schedule defined, assuming not in block time.")
            return false
        }

        val nowCal = Calendar.getInstance()
        val currentDayOfWeek = nowCal.get(Calendar.DAY_OF_WEEK) // Sunday is 1, Saturday is 7
        val adjustedDayOfWeek = if (currentDayOfWeek == Calendar.SUNDAY) 7 else currentDayOfWeek - 1 // DateTime: Mon=1, Sun=7

        val todayScheduleEntryMap = currentSchedule.firstOrNull {
            (it["dayOfWeek"] as? Number)?.toInt() == adjustedDayOfWeek && (it["isEnabled"] as? Boolean) == true
        }

        if (todayScheduleEntryMap == null) {
            Log.d(TAG, "No active schedule for today (Day: $adjustedDayOfWeek).")
            return false
        }

        val startTimeStr = todayScheduleEntryMap["startTime"] as? String
        val endTimeStr = todayScheduleEntryMap["endTime"] as? String

        if (startTimeStr == null || endTimeStr == null) {
            Log.d(TAG, "Schedule for today (Day $adjustedDayOfWeek) is enabled but start/end time missing.")
            return false
        }

        try {
            val startParts = startTimeStr.split(":")
            val endParts = endTimeStr.split(":")
            if (startParts.size != 2 || endParts.size != 2) {
                 Log.e(TAG, "Invalid time format in schedule: Start=$startTimeStr, End=$endTimeStr")
                return false
            }
            val startHour = startParts[0].toInt()
            val startMinute = startParts[1].toInt()
            val endHour = endParts[0].toInt()
            val endMinute = endParts[1].toInt()

            val startCal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, startHour)
                set(Calendar.MINUTE, startMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val endCal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, endHour)
                set(Calendar.MINUTE, endMinute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val nowMillis = nowCal.timeInMillis
            val startMillis = startCal.timeInMillis
            var endMillis = endCal.timeInMillis

            if (endMillis <= startMillis) { // Handles overnight schedule, e.g., 22:00 - 02:00
                endMillis += 24 * 60 * 60 * 1000 // Add 24 hours to end time
                 // Check if 'now' is after start OR before original end (on the next day)
                if (nowMillis >= startMillis || nowMillis < endCal.timeInMillis) {
                     Log.d(TAG, "Currently IN scheduled block (overnight type 1): $startTimeStr - $endTimeStr")
                     return true
                }
                // Alternative check for overnight if now is on the "second day" part of an overnight schedule
                // This is implicitly covered if nowMillis < endCal.timeInMillis (original end time)
                // and the day started yesterday after startMillis.
                // A simpler way for overnight:
                // if (nowCal.timeInMillis >= startCal.timeInMillis) -> it's same day after start
                // if (nowCal.timeInMillis < endCal.timeInMillis) -> it's next day before end
                // So, if (start time is 22:00, end time is 02:00)
                //    current time 23:00 -> now >= start (true)
                //    current time 01:00 -> now < end (true)
                // This logic needs to be careful.
                // If end time is earlier than start time, it implies crossing midnight.
                // Is current time >= start_time (today) OR is current time < end_time (today, but conceptually for "next day's segment")
                // This means we have two windows: [start_time, 23:59:59] and [00:00:00, end_time]
                val beforeMidnightEnd = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 23)
                    set(Calendar.MINUTE, 59)
                    set(Calendar.SECOND, 59)
                }
                val afterMidnightStart = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                }
                if ((nowMillis >= startMillis && nowMillis <= beforeMidnightEnd.timeInMillis) ||
                    (nowMillis >= afterMidnightStart.timeInMillis && nowMillis < endCal.timeInMillis)) {
                     Log.d(TAG, "Currently IN scheduled block (overnight refined): $startTimeStr - $endTimeStr")
                     return true
                }

            } else { // Ends on the same day
                 if (nowMillis >= startMillis && nowMillis < endMillis) {
                    Log.d(TAG, "Currently IN scheduled block (sameday): $startTimeStr - $endTimeStr")
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing schedule times for day $adjustedDayOfWeek: Start=$startTimeStr, End=$endTimeStr", e)
            return false
        }
        Log.d(TAG, "Currently OUTSIDE scheduled block for day $adjustedDayOfWeek: $startTimeStr - $endTimeStr")
        return false
    }

    private fun showLockScreen() {
        Log.i(TAG, "Attempting to show LockScreenActivity for $currentForegroundAppPackage")
        val intent = Intent(applicationContext, LockScreenActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            // NO_HISTORY is good, EXCLUDE_FROM_RECENTS can also be set in manifest
        }
        try {
            applicationContext.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting LockScreenActivity: ${e.message}", e)
        }
    }

    private fun hideLockScreen() {
        Log.d(TAG, "Sending broadcast to close lock screen.")
        applicationContext.sendBroadcast(Intent(LockScreenActivity.ACTION_CLOSE_LOCK_SCREEN))
    }

    private fun startScreenTimeDeduction(packageName: String) {
        if (screenTimeDeductionTimer != null && currentlyTrackedAppPackageForDeduction == packageName) {
            Log.d(TAG, "Screen time deduction already running for $packageName")
            return
        }
        stopScreenTimeDeductionTimer()

        currentlyTrackedAppPackageForDeduction = packageName
        Log.i(TAG, "Starting screen time deduction for $packageName. Current time: $earnedScreenTimeMs ms")
        sendScreenTimeUpdateToFlutter(earnedScreenTimeMs) // Send initial state

        screenTimeDeductionTimer = Timer()
        screenTimeDeductionTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                if (currentForegroundAppPackage != currentlyTrackedAppPackageForDeduction || !isAppCurrentlyBlocked(currentForegroundAppPackage ?: "") || !isCurrentTimeInScheduledBlock()) {
                    Log.d(TAG, "Condition for deduction no longer met. FG: $currentForegroundAppPackage, Tracked: $currentlyTrackedAppPackageForDeduction. Stopping deduction.")
                    stopScreenTimeDeductionTimer()
                    handler.post { evaluateCurrentState() } // Re-evaluate state, might hide lock screen etc.
                    return
                }

                if (earnedScreenTimeMs > 0) {
                    earnedScreenTimeMs -= 1000
                    if(earnedScreenTimeMs < 0) earnedScreenTimeMs = 0
                    Log.d(TAG, "Deducting screen time for $currentlyTrackedAppPackageForDeduction. Remaining: $earnedScreenTimeMs ms")
                    sendScreenTimeUpdateToFlutter(earnedScreenTimeMs)

                    if (earnedScreenTimeMs == 0L) {
                        Log.i(TAG, "Screen time exhausted for $currentlyTrackedAppPackageForDeduction. Triggering block.")
                        // Timer will be stopped by the next evaluateCurrentState if conditions change or by itself
                        handler.post { evaluateCurrentState() } // This will show lock screen
                    }
                } else { // Should ideally be caught by earnedScreenTimeMs == 0L above
                    Log.w(TAG, "Deduction timer ran but screen time already zero for $currentlyTrackedAppPackageForDeduction.")
                    stopScreenTimeDeductionTimer() // Stop to prevent multiple evaluations
                    handler.post { evaluateCurrentState() } // This will ensure lock screen is shown
                }
            }
        }, 1000, 1000)
    }

    private fun stopScreenTimeDeductionTimer() {
        if (screenTimeDeductionTimer != null) {
            Log.d(TAG, "Stopping screen time deduction timer for $currentlyTrackedAppPackageForDeduction")
            screenTimeDeductionTimer?.cancel()
            screenTimeDeductionTimer = null
        }
        if (currentlyTrackedAppPackageForDeduction != null) {
             // If timer stops, means app is no longer eligible for using screen time (e.g., switched app, or time ran out)
             // Send final update if it was being tracked.
            // sendScreenTimeUpdateToFlutter(earnedScreenTimeMs) // Or rely on evaluateCurrentState to do this
        }
        currentlyTrackedAppPackageForDeduction = null
    }

    private fun sendScreenTimeUpdateToFlutter(timeMs: Long) {
        Log.d(TAG, "Sending screen time update to Flutter: $timeMs ms")
        // Ensure this is called on the main thread if the sink requires it
        handler.post {
            try {
                screenTimeEventSink?.success(timeMs)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending screen time update to Flutter: ${e.message}", e)
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "TaskTime Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Channel for TaskTime background monitoring service."
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
            Log.d(TAG, "Notification channel created.")
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, pendingIntentFlags)

        val notificationIcon = android.R.drawable.ic_dialog_info // System default as placeholder

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("TaskTime Active")
            .setContentText("Monitoring app usage and tasks.")
            .setSmallIcon(notificationIcon)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? {
        Log.d(TAG, "Service onBind called, returning null.")
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopScreenTimeDeductionTimer()
        Log.i(TAG, "Service onDestroy. Cleaning up...")
    }
}
