package com.safenest.safenest

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.safenest.emergency/call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "makeCall" -> {
                        val number = call.argument<String>("number") ?: EmergencyCallService.EMERGENCY_NUMBER
                        try {
                            EmergencyCallService.placeCall(applicationContext, number, "makeCall")
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CALL_FAILED", e.message, null)
                        }
                    }
                    "triggerEmergency" -> {
                        val reason = call.argument<String>("reason") ?: "Alert"
                        try {
                            EmergencyCallService.placeCall(applicationContext, reason = reason)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("EMERGENCY_FAILED", e.message, null)
                        }
                    }
                    "writeAlerts" -> {
                        val fall = call.argument<Boolean>("fall") ?: false
                        val tempAlert = call.argument<Boolean>("tempAlert") ?: false
                        val simOffline = call.argument<Boolean>("simOffline") ?: false
                        try {
                            SafeNestForegroundService.writeAlerts(
                                applicationContext, fall, tempAlert, simOffline
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("WRITE_FAILED", e.message, null)
                        }
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(intent)
                            result.success(false)
                        }
                    }
                    "openBatterySettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
