import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'environment_service.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // Configuration flags
  bool _isDemoMode = false;
  bool _firestoreAvailable = true;
  String? _firestoreErrorMessage;

  // Getters
  bool get isDemoMode => _isDemoMode || EnvironmentService().forceDemoMode;
  bool get isFirestoreAvailable => _firestoreAvailable;
  String? get firestoreErrorMessage => _firestoreErrorMessage;
  bool get shouldUseFirestore => _firestoreAvailable;

  /// Initialize the configuration service
  /// This should be called early in the app lifecycle
  Future<void> initialize() async {
    print('ConfigService: Initializing...');
    print('ConfigService: Platform - Web: $kIsWeb');
    print('ConfigService: Force Demo Mode: ${EnvironmentService().forceDemoMode}');

    // Check if force demo mode is enabled in environment
    if (EnvironmentService().forceDemoMode) {
      _isDemoMode = true;
      _firestoreAvailable = false;
      print('ConfigService: Force demo mode enabled');
      return;
    }

    // Test Firestore connectivity regardless of platform
    await _testFirestoreConnectivity();
  }

  /// Test if Firestore is available and accessible
  Future<void> _testFirestoreConnectivity() async {
    try {
      print('ConfigService: Testing Firestore connectivity...');

      // Try a simple Firestore operation
      final firestore = FirebaseFirestore.instance;

      // Test with a timeout
      final testDoc = await firestore
          .collection('_connection_test')
          .doc('test')
          .get()
          .timeout(Duration(seconds: 5));

      _firestoreAvailable = true;
      _isDemoMode = false;
      _firestoreErrorMessage = null;

      print('ConfigService: Firestore connectivity test passed');
    } catch (e) {
      print('ConfigService: Firestore connectivity test failed: $e');

      _firestoreAvailable = false;
      _isDemoMode = true;
      _firestoreErrorMessage = e.toString();

      // Check for specific error types
      if (e.toString().contains('PERMISSION_DENIED')) {
        _firestoreErrorMessage = 'Firestore API not enabled. Please enable it in Firebase Console.';
      } else if (e.toString().contains('UNAVAILABLE')) {
        _firestoreErrorMessage = 'Firestore service unavailable. Check internet connection.';
      }

      print('ConfigService: Falling back to demo mode due to Firestore error');
    }
  }

  /// Force demo mode (useful for testing)
  void enableDemoMode() {
    _isDemoMode = true;
    _firestoreAvailable = false;
    print('ConfigService: Demo mode manually enabled');
  }

  /// Retry Firestore connection
  Future<bool> retryFirestoreConnection() async {
    if (kIsWeb) return false;

    await _testFirestoreConnectivity();
    return _firestoreAvailable;
  }

  /// Get demo user ID for consistent demo experience
  String getDemoUserId() {
    try {
      final auth = FirebaseAuth.instance;
      return auth.currentUser?.uid ?? 'demo_user_${DateTime.now().day}';
    } catch (e) {
      // Fallback when Firebase is not initialized (e.g., in tests)
      return 'demo_user_${DateTime.now().day}';
    }
  }

  static int _idCounter = 0;

  /// Generate consistent demo IDs
  String generateDemoId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _idCounter++;
    return '${prefix}_demo_${timestamp}_${_idCounter}';
  }

  /// Log configuration state for debugging
  void logConfigState() {
    if (kDebugMode) {
      print('ConfigService State:');
      print('  - Is Web: $kIsWeb');
      print('  - Demo Mode: $_isDemoMode');
      print('  - Firestore Available: $_firestoreAvailable');
      print('  - Should Use Firestore: $shouldUseFirestore');
      if (_firestoreErrorMessage != null) {
        print('  - Firestore Error: $_firestoreErrorMessage');
      }
    }
  }

  /// Get user-friendly error message for UI display
  String getUserFriendlyErrorMessage() {
    if (!_firestoreAvailable && _firestoreErrorMessage != null) {
      if (_firestoreErrorMessage!.contains('PERMISSION_DENIED')) {
        return 'Service temporarily unavailable. Running in demo mode.';
      } else if (_firestoreErrorMessage!.contains('UNAVAILABLE')) {
        return 'Connection issue. Please check your internet connection.';
      }
    }
    return 'Running in demo mode for testing.';
  }

  /// Check if we should show a warning to the user about demo mode
  bool shouldShowDemoWarning() {
    return _isDemoMode && !kIsWeb && !_firestoreAvailable;
  }

  /// Reset configuration state for testing purposes only
  @visibleForTesting
  void resetForTesting() {
    _isDemoMode = false;
    _firestoreAvailable = true;
    _firestoreErrorMessage = null;
    _idCounter = 0;
  }
}