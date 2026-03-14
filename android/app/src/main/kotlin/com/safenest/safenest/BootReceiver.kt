package com.safenest.safenest

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("BootReceiver", "Received: $action")
        if (
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED
        ) {
            Log.d("BootReceiver", "Restarting SafeNest foreground service")
            val serviceIntent = Intent(context, SafeNestForegroundService::class.java)
            serviceIntent.action = "START"
            try {
                context.startForegroundService(serviceIntent)
                Log.d("BootReceiver", "Service restart requested")
            } catch (e: Exception) {
                Log.e("BootReceiver", "Failed to restart service: ${e.message}")
            }
        }
    }
}
