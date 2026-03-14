package com.safenest.safenest

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class SafeNestForegroundService : Service() {

    private val CHANNEL_ID = "safenest_watchdog"
    private val NOTIF_ID = 9999
    private lateinit var prefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private var lastFall = false
    private var lastTemp = false
    private var lastCallTime = 0L
    private val COOLDOWN_MS = 60_000L

    private val pollRunnable = object : Runnable {
        override fun run() {
            checkAlerts()
            handler.postDelayed(this, 2000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification(
            "SafeNest Active", "Monitoring your safety..."))
        handler.post(pollRunnable)
        Log.d("SafeNestFGService", "Service created — polling FlutterSharedPreferences")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("SafeNestFGService", "onStartCommand: ${intent?.action}")
        // Re-attach prefs in case service was restarted
        if (!::prefs.isInitialized) {
            prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        }
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d("SafeNestFGService", "onTaskRemoved — scheduling restart")
        val restartIntent = Intent(applicationContext, SafeNestForegroundService::class.java)
        restartIntent.action = "RESTART"
        startForegroundService(restartIntent)
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d("SafeNestFGService", "onDestroy — restarting self")
        handler.removeCallbacks(pollRunnable)
        val restartIntent = Intent(applicationContext, SafeNestForegroundService::class.java)
        startForegroundService(restartIntent)
        super.onDestroy()
    }

    private fun checkAlerts() {
        // Read keys written by Flutter's shared_preferences plugin
        // Flutter stores keys with "flutter." prefix in FlutterSharedPreferences
        val fall     = prefs.getBoolean("flutter.safenest_fall", false)
        val temp     = prefs.getBoolean("flutter.safenest_temp_alert", false)
        val simOffline = prefs.getBoolean("flutter.safenest_sim_offline", false)
        val now      = System.currentTimeMillis()
        val onCooldown = (now - lastCallTime) < COOLDOWN_MS

        Log.v("SafeNestFGService",
            "Poll — fall:$fall temp:$temp simOffline:$simOffline cooldown:$onCooldown")

        // Fall — leading edge
        if (fall && !lastFall && !onCooldown) {
            Log.d("SafeNestFGService", "🚨 FALL DETECTED")
            updateNotification("🚨 FALL DETECTED", "Emergency call being placed!")
            if (simOffline) {
                lastCallTime = now
                EmergencyCallService.placeCall(applicationContext, reason = "FALL DETECTED")
            }
        }

        // Temp — leading edge
        if (temp && !lastTemp && !onCooldown) {
            Log.d("SafeNestFGService", "🌡️ HIGH TEMP")
            updateNotification("🌡️ HIGH TEMPERATURE", "Emergency call being placed!")
            if (simOffline) {
                lastCallTime = now
                EmergencyCallService.placeCall(applicationContext, reason = "HIGH TEMP")
            }
        }

        // All clear
        if (!fall && !temp && (lastFall || lastTemp)) {
            updateNotification("SafeNest Active", "Monitoring your safety...")
        }

        lastFall = fall
        lastTemp = temp
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SafeNest Watchdog",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "SafeNest safety monitoring"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String, text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(title: String, text: String) {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIF_ID, buildNotification(title, text))
    }

    companion object {
        // Called from MainActivity MethodChannel — writes to FlutterSharedPreferences
        // so native service can read without Flutter engine
        fun writeAlerts(
            context: Context,
            fall: Boolean,
            tempAlert: Boolean,
            simOffline: Boolean
        ) {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean("flutter.safenest_fall", fall)
                .putBoolean("flutter.safenest_temp_alert", tempAlert)
                .putBoolean("flutter.safenest_sim_offline", simOffline)
                .apply()
            Log.d("SafeNestFGService",
                "writeAlerts — fall:$fall temp:$tempAlert simOffline:$simOffline")
        }
    }
}
