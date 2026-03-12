import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/health_data_model.dart';
import 'storage_service.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[Firebase] Signed in: ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Firebase] Sign in error: ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[Firebase] Signed up: ${cred.user?.email}');
      await _createUserProfile(cred.user!);
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Firebase] Sign up error: ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('[Firebase] Signed out');
  }

  Future<void> _createUserProfile(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': StorageService.userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String bloodGroup,
    required int age,
    required String emergencyContact,
    DateTime? pregnancyStartDate,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'blood_group': bloodGroup,
        'age': age,
        'emergency_contact': emergencyContact,
        'pregnancy_start_date': pregnancyStartDate?.toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[Firebase] User profile saved');
    } catch (e) {
      debugPrint('[Firebase] saveUserProfile error: $e');
    }
  }

  // ─── Firestore — Health Data ───────────────────────────────────────────────

  Future<void> saveHealthData(HealthDataModel model) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('health_data')
          .add({
        'temperature': model.temperature,
        'fall_detected': model.fallDetected,
        'heart_rate': model.heartRate,
        'temp_alert': model.tempAlert,
        'sim_signal': model.simSignal,
        'network_type': model.networkType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firebase] saveHealthData error: $e');
    }
  }

  Future<void> saveFallEvent(HealthDataModel model) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('fall_events')
          .add({
        'temperature': model.temperature,
        'timestamp': FieldValue.serverTimestamp(),
        'location_lat': model.gpsLat,
        'location_lng': model.gpsLng,
      });
      debugPrint('[Firebase] Fall event saved');
    } catch (e) {
      debugPrint('[Firebase] saveFallEvent error: $e');
    }
  }

  Stream<QuerySnapshot> getHealthHistory() {
    final uid = currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('health_data')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // ─── FCM ───────────────────────────────────────────────────────────────────

  Future<void> initFCM() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      final token = await _fcm.getToken();
      debugPrint('[FCM] Token: $token');

      if (token != null) await _saveFCMToken(token);

      _fcm.onTokenRefresh.listen(_saveFCMToken);

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('[FCM] initFCM error: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'fcm_token': token,
      'token_updated_at': FieldValue.serverTimestamp(),
    });
  }
}
