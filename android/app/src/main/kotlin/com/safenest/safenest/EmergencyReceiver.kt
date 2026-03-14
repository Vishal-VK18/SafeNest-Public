package com.safenest.safenest

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class EmergencyReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_EMERGENCY = "com.safenest.EMERGENCY_CALL"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("EmergencyReceiver", "onReceive action: ${intent.action}")
        if (intent.action == ACTION_EMERGENCY) {
            val reason = intent.getStringExtra("reason") ?: "Alert"
            Log.d("EmergencyReceiver", "Emergency broadcast — reason: $reason")
            EmergencyCallService.placeCall(context, reason = reason)
        }
    }
}
