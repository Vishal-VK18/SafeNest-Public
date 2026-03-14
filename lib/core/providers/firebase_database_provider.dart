import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safenest/core/providers/auth_provider.dart';
import 'package:safenest/core/services/firebase_database_service.dart';

final firebaseDatabaseServiceProvider =
  Provider<FirebaseDatabaseService>((ref) {
    final uid = ref.watch(currentUidProvider);
    return FirebaseDatabaseService(uid: uid);
  });
