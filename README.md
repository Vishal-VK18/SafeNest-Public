# SafeNest 🤱

### A Pregnancy-Focused Smart Safety Wearable with Autonomous Emergency Alert System

SafeNest is a two-unit IoT wearable system designed to keep pregnant women safe
by continuously monitoring vital signs and automatically placing emergency calls
when a fall or abnormal temperature is detected — no phone interaction required.

---

## 🎯 Problem Statement

Pregnant women living alone or in low-supervision environments face serious risks
from falls and fever. Existing wearables only notify — they do not act.
SafeNest acts autonomously.

---

## 🚀 Features

- 🌡️ **Real-time Temperature Monitoring** — TMP117 high precision sensor
- 🤸 **Fall Detection** — MPU6050 accelerometer + gyroscope
- ❤️ **Heart Rate & SpO₂** — MAX30102 sensor
- 📞 **Autonomous Emergency Call** — SIM A7670E 4G LTE module calls emergency contact directly without phone
- 📱 **Flutter Mobile App** — live health dashboard, alerts, event history
- 🔔 **Push Notifications** — Firebase FCM alerts even when app is closed
- 🔒 **App-Closed Emergency** — Kotlin native background service handles alerts 24/7
- 📡 **Wireless** — BLE 5.0 watch to app, ESP-NOW watch to SIM unit

---

## 🏗️ System Architecture
```
Sensors → ESP32-C3 → BLE 5.0 → Flutter App → Firebase Cloud
                  ↓
             ESP-NOW 2.4GHz
                  ↓
           SIM A7670E 4G LTE
                  ↓
          Emergency Call Placed
```

---

## ⚡ Emergency Flow
```
Fall Detected
     ↓
ESP32 Triggers Alert
     ↓
ESP-NOW to SIM Unit
     ↓
SIM A7670E Dials Emergency Contact
     ↓
Contact Notified
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) · Riverpod |
| Embedded Firmware | Arduino C++ · ESP32-C3 Mini |
| Native Android | Kotlin · Foreground Service |
| Sensors | TMP117 · MPU6050 · MAX30102 |
| Emergency Module | SIM A7670E 4G LTE |
| Communication | BLE 5.0 · ESP-NOW · UART · I2C |
| Database | Firebase Firestore · Hive |
| Cloud | Firebase Auth · FCM |
| Hosting | Vercel |

---

## 📦 Hardware Components

### Watch Unit
- Seeed XIAO ESP32-C3 Mini
- TMP117 Temperature Sensor
- MPU6050 Accelerometer + Gyroscope
- MAX30102 Heart Rate + SpO₂
- W25Q128 128Mbit Flash Storage
- 3.7V 500mAh Li-Po Battery

### Communication Unit
- Seeed XIAO ESP32-C3 Mini
- SIM A7670E 4G LTE + GPS Module
- 4G LTE SMA Antenna
- GNSS Antenna
- 3.7V 2000mAh Li-Po Battery
- 1000µF Power Capacitor

---

## 🔧 Setup & Installation

### Flutter App
```bash
git clone https://github.com/Vishal-VK18/SafeNest-Public.git
cd SafeNest-Public
flutter pub get
flutter run
```

### ESP32 Firmware
- Open `firmware/` folder in Arduino IDE
- Install required libraries:
  - Adafruit TMP117
  - Adafruit MPU6050
  - ESP32 BLE Arduino
- Upload to Seeed XIAO ESP32-C3

---

## 📲 Direct Install (Android)

Download the latest APK from [Releases](../../releases/latest)
and install directly on your Android device.

> Enable "Install from unknown sources" in Android settings before installing.

---

## 🌐 Website

[https://safenestc.netlify.app/](https://safenestc.netlify.app/)

---

## 👥 Team

Built with ❤️ for maternal safety.

---

## 📄 License

This project is for educational and hackathon purposes.
