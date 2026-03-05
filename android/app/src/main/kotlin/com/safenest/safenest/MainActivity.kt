package com.safenest.safenest

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.safenest.safenest/ble_monitor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intent = Intent(this, BleMonitorService::class.java).apply {
                            action = BleMonitorService.ACTION_START
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "stopService" -> {
                        val intent = Intent(this, BleMonitorService::class.java).apply {
                            action = BleMonitorService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(true)
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
                            // Fallback — open battery settings
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(intent)
                            result.success(false)
                        }
                    }
                    "openBatterySettings" -> {
                        // For Vivo/Xiaomi/Oppo — open app-specific battery settings
                        try {
                            val intent = Intent().apply {
                                when {
                                    Build.MANUFACTURER.equals("vivo", ignoreCase = true) -> {
                                        component = android.content.ComponentName(
                                            "com.vivo.permissionmanager",
                                            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                                        )
                                    }
                                    Build.MANUFACTURER.equals("xiaomi", ignoreCase = true) -> {
                                        component = android.content.ComponentName(
                                            "com.miui.securitycenter",
                                            "com.miui.permcenter.autostart.AutoStartManagementActivity"
                                        )
                                    }
                                    Build.MANUFACTURER.equals("oppo", ignoreCase = true) -> {
                                        component = android.content.ComponentName(
                                            "com.coloros.safecenter",
                                            "com.coloros.safecenter.permission.startup.FakeActivity"
                                        )
                                    }
                                    Build.MANUFACTURER.equals("huawei", ignoreCase = true) -> {
                                        component = android.content.ComponentName(
                                            "com.huawei.systemmanager",
                                            "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                                        )
                                    }
                                    Build.MANUFACTURER.equals("samsung", ignoreCase = true) -> {
                                        action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                        data = Uri.parse("package:$packageName")
                                    }
                                    else -> {
                                        action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                        data = Uri.parse("package:$packageName")
                                    }
                                }
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(fallback)
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
