package com.tasktime.app

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import androidx.core.content.ContextCompat // For ContextCompat.registerReceiver

class LockScreenActivity : Activity() {

    companion object {
        const val ACTION_CLOSE_LOCK_SCREEN = "com.tasktime.app.ACTION_CLOSE_LOCK_SCREEN"
        private const val TAG = "LockScreenActivity"
        // TODO: Add extras for dynamic message/time if needed
    }

    private val closeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_CLOSE_LOCK_SCREEN) {
                Log.d(TAG, "Received broadcast to close lock screen. Finishing activity.")
                finishAndRemoveTask() // Ensures it's removed from recents too
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_lock_screen)
        Log.d(TAG, "LockScreenActivity created.")

        // Make activity fullscreen or adjust theme for overlay effect
        // Theme might be better: android:theme="@android:style/Theme.Translucent.NoTitleBar.Fullscreen" in Manifest

        val returnButton: Button = findViewById(R.id.returnToAppButton)
        returnButton.setOnClickListener {
            Log.d(TAG, "Return to TaskTime button clicked.")
            // Option 1: Just finish this activity
            finishAndRemoveTask()

            // Option 2: Bring TaskTime's MainActivity to front
            // val mainAppIntent = Intent(this, MainActivity::class.java)
            // mainAppIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            // startActivity(mainAppIntent)
            // finish() // then finish this one
        }

        // TODO: Update time remaining dynamically if passed via Intent or from a shared source
        // val timeTextView: TextView = findViewById(R.id.lockScreenTime)
        // timeTextView.text = "Time Remaining: Xm Xs"

        // Register broadcast receiver to listen for close command
        // For Android TIRAMISU (33) and above, need to specify receiver export status
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.registerReceiver(this, closeReceiver, IntentFilter(ACTION_CLOSE_LOCK_SCREEN), ContextCompat.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(closeReceiver, IntentFilter(ACTION_CLOSE_LOCK_SCREEN))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(closeReceiver)
        Log.d(TAG, "LockScreenActivity destroyed.")
    }

    override fun onBackPressed() {
        // Prevent back button from closing the lock screen easily
        // super.onBackPressed() // Comment out to disable back button
        Log.d(TAG, "Back button pressed on LockScreenActivity. Doing nothing by default.")
        // Or, could also trigger return to TaskTime logic
        // findViewById<Button>(R.id.returnToAppButton).performClick()
    }
}
