package com.safenest.safenest

import android.app.Application
import android.content.Intent
import android.util.Log

class Application : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d("SafeNestApp", "Application onCreate — starting watchdog")
        // Auto-start watchdog service when app process starts
        try {
            val intent = Intent(this, SafeNestForegroundService::class.java)
            intent.action = "START"
            startForegroundService(intent)
        } catch (e: Exception) {
            Log.e("SafeNestApp", "Failed to start watchdog: ${e.message}")
        }
    }
}
