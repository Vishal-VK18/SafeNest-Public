package com.safenest.safenest

import android.app.*
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.*
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class BleMonitorService : Service() {

    companion object {
        const val TAG = "BleMonitorService"
        const val SERVICE_UUID = "12345678-1234-1234-1234-123456789abc"
        const val CHAR_UUID = "abcd1234-ab12-ab12-ab12-abcdef123456"
        const val WATCH_NAME = "SafeNest Band"
        const val TEMP_THRESHOLD = 38.0
        const val CHANNEL_MONITOR = "safenest_monitoring"
        const val CHANNEL_ALERTS = "safenest_alerts"
        const val NOTIF_ID_MONITOR = 999
        const val NOTIF_ID_FALL = 1001
        const val NOTIF_ID_TEMP = 1003
        const val ACTION_START = "START"
        const val ACTION_STOP = "STOP"
    }

    private var bluetoothGatt: BluetoothGatt? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var scanning = false
    private var lastFall = false
    private var connected = false
    private val handler = Handler(Looper.getMainLooper())
    private val scanPeriod = 15000L
    private val rescanDelay = 10000L

    private val leScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            if (device.name == WATCH_NAME && !connected) {
                Log.d(TAG, "Found SafeNest Band — connecting")
                stopBleScan()
                connectToDevice(device)
            }
        }
        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Scan failed: $errorCode")
            scanning = false
            scheduleRescan()
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    Log.d(TAG, "Connected to watch")
                    connected = true
                    gatt.discoverServices()
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    Log.d(TAG, "Disconnected — rescanning")
                    connected = false
                    bluetoothGatt?.close()
                    bluetoothGatt = null
                    scheduleRescan()
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                scheduleRescan()
                return
            }
            val service = gatt.getService(java.util.UUID.fromString(SERVICE_UUID))
            val char = service?.getCharacteristic(java.util.UUID.fromString(CHAR_UUID))
            if (char != null) {
                gatt.setCharacteristicNotification(char, true)
                val descriptor = char.getDescriptor(
                    java.util.UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
                )
                descriptor?.let {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        gatt.writeDescriptor(it, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
                    } else {
                        @Suppress("DEPRECATION")
                        it.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                        gatt.writeDescriptor(it)
                    }
                }
                Log.d(TAG, "Subscribed to characteristic")
            } else {
                Log.e(TAG, "Characteristic not found")
                scheduleRescan()
            }
        }

        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            val raw = characteristic.value?.toString(Charsets.UTF_8)?.trim() ?: return
            Log.d(TAG, "BLE data: $raw")
            handler.post { handleData(raw) }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            val raw = value.toString(Charsets.UTF_8).trim()
            Log.d(TAG, "BLE data (API33+): $raw")
            handler.post { handleData(raw) }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: ${intent?.action}")
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                startForeground(
                    NOTIF_ID_MONITOR,
                    buildMonitorNotification("SafeNest is monitoring your health")
                )
                if (!connected && !scanning) {
                    startBleScan()
                }
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed — scheduling restart")
        stopBleScan()
        bluetoothGatt?.close()
        bluetoothGatt = null
        // Restart self when killed
        val restartIntent = Intent(applicationContext, BleMonitorService::class.java).apply {
            action = ACTION_START
        }
        val pendingIntent = PendingIntent.getService(
            applicationContext, 1, restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 5000,
            pendingIntent
        )
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "Task removed — restarting service")
        val restartIntent = Intent(applicationContext, BleMonitorService::class.java).apply {
            action = ACTION_START
        }
        val pendingIntent = PendingIntent.getService(
            applicationContext, 1, restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 3000,
            pendingIntent
        )
    }

    private fun startBleScan() {
        if (scanning || connected) return
        val scanner = bluetoothAdapter?.bluetoothLeScanner
        if (scanner == null) {
            Log.e(TAG, "BLE scanner not available")
            scheduleRescan()
            return
        }
        scanning = true
        Log.d(TAG, "Starting BLE scan")
        handler.postDelayed({
            if (scanning) stopBleScan()
        }, scanPeriod)
        scanner.startScan(leScanCallback)
    }

    private fun stopBleScan() {
        if (!scanning) return
        scanning = false
        try {
            bluetoothAdapter?.bluetoothLeScanner?.stopScan(leScanCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Stop scan error: $e")
        }
    }

    private fun scheduleRescan() {
        if (connected) return
        Log.d(TAG, "Rescanning in ${rescanDelay}ms")
        handler.postDelayed({ startBleScan() }, rescanDelay)
    }

    private fun connectToDevice(device: BluetoothDevice) {
        bluetoothGatt = device.connectGatt(this, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
    }

    private fun handleData(raw: String) {
        val parts = raw.split(",")
        val temp = parts.getOrNull(0)?.trim()?.toDoubleOrNull() ?: return
        val fall = parts.getOrNull(1)?.trim() == "1"
        val tempAlert = parts.getOrNull(2)?.trim()?.toIntOrNull() ?: 0

        updateMonitorNotification("Temp: ${String.format("%.1f", temp)}°C — Monitoring active")

        // Fall alert
        if (fall && !lastFall) {
            Log.d(TAG, "FALL DETECTED")
            showAlertNotification(
                id = NOTIF_ID_FALL,
                title = "⚠️ Fall Detected!",
                body = "A sudden fall was detected. Emergency contacts will be notified."
            )
        }

        // High temperature alert (Flag = 1)
        if (tempAlert == 1) {
            Log.d(TAG, "HIGH TEMP ALERT")
            showAlertNotification(
                id = NOTIF_ID_TEMP,
                title = "🌡️ High Body Temperature",
                body = "Temperature is ${String.format("%.1f", temp)}°C — above safe threshold."
            )
        }

        // Low temperature alert (Flag = -1)
        if (tempAlert == -1) {
            Log.d(TAG, "LOW TEMP ALERT")
            showAlertNotification(
                id = 1006, // Matches AppConstants.notifIdLowTemperature
                title = "❄️ Low Body Temperature",
                body = "Temperature is ${String.format("%.1f", temp)}°C — below safe threshold."
            )
        }

        lastFall = fall
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val monitorChannel = NotificationChannel(
                CHANNEL_MONITOR,
                "SafeNest Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "SafeNest is monitoring your health"
                setShowBadge(false)
            }
            val alertChannel = NotificationChannel(
                CHANNEL_ALERTS,
                "SafeNest Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Health and safety alerts"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(monitorChannel)
            manager.createNotificationChannel(alertChannel)
        }
    }

    private fun buildMonitorNotification(text: String): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_MONITOR)
            .setContentTitle("SafeNest Band")
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateMonitorNotification(text: String) {
        val notification = buildMonitorNotification(text)
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIF_ID_MONITOR, notification)
    }

    private fun showAlertNotification(id: Int, title: String, body: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ALERTS)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()
        try {
            NotificationManagerCompat.from(this).notify(id, notification)
        } catch (e: SecurityException) {
            Log.e(TAG, "Notification permission denied: $e")
        }
    }
}
