import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Connects Firebase services to local emulators if `--dart-define=USE_EMULATOR=true` is set.
void connectToEmulatorsIfEnabled() {
  const useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
  if (!useEmulator) return;

  final host = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      ? '10.0.2.2'
      : 'localhost';

  debugPrint('⚡ CONNECTING TO FIREBASE EMULATOR SUITE AT $host');

  try {
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    debugPrint('✅ Successfully connected to Auth (9099), Firestore (8080), Functions (5001)');
  } catch (e) {
    debugPrint('⚠️ Error connecting to Firebase Emulators: $e');
  }
}
