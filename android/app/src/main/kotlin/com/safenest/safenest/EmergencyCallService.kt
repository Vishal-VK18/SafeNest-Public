package com.safenest.safenest

import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.IBinder
import android.util.Log

class EmergencyCallService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val number = intent?.getStringExtra("number") ?: "8778387508"
        val reason = intent?.getStringExtra("reason") ?: "Alert"
        Log.d("EmergencyCallService", "[$reason] Placing call to $number")
        try {
            val callIntent = Intent(Intent.ACTION_CALL)
            callIntent.data = Uri.parse("tel:$number")
            callIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            applicationContext.startActivity(callIntent)
            Log.d("EmergencyCallService", "Call intent fired successfully")
        } catch (e: Exception) {
            Log.e("EmergencyCallService", "Call failed: ${e.message}")
        }
        stopSelf()
        return START_NOT_STICKY
    }

    companion object {
        const val EMERGENCY_NUMBER = "8778387508"

        fun placeCall(context: Context, number: String = EMERGENCY_NUMBER, reason: String = "Alert") {
            Log.d("EmergencyCallService", "placeCall() triggered — reason: $reason")
            val intent = Intent(context, EmergencyCallService::class.java)
            intent.putExtra("number", number)
            intent.putExtra("reason", reason)
            context.startService(intent)
        }
    }
}
