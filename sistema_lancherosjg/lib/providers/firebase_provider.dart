import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

/// Provider del servicio de Firebase (singleton)
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
