import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterfilternet/services/config_service.dart';

void main() {
  group('ConfigService Tests', () {
    setUp(() {
      // Reset ConfigService state before each test
      final configService = ConfigService();
      configService.resetForTesting();
    });

    test('ConfigService should initialize correctly', () async {
      final configService = ConfigService();

      // Test initial state - on web, demo mode is always true due to kIsWeb
      if (kIsWeb) {
        expect(configService.isDemoMode, isTrue);
        expect(configService.isFirestoreAvailable, isFalse); // Always false on web
      } else {
        expect(configService.isDemoMode, isFalse);
        expect(configService.isFirestoreAvailable, isTrue); // Default true until tested
      }
    });

    test('ConfigService should generate consistent demo IDs', () async {
      final configService = ConfigService();

      final orderId1 = configService.generateDemoId('order');
      await Future.delayed(Duration(milliseconds: 10)); // Small delay to ensure different timestamps
      final orderId2 = configService.generateDemoId('order');

      expect(orderId1, startsWith('order_demo_'));
      expect(orderId2, startsWith('order_demo_'));
      expect(orderId1, isNot(equals(orderId2))); // Should be different due to counter
    });

    test('ConfigService should provide user-friendly error messages', () {
      final configService = ConfigService();

      final message = configService.getUserFriendlyErrorMessage();
      expect(message, isNotEmpty);
      expect(message, contains('demo mode'));
    });

    test('ConfigService should handle demo mode correctly', () {
      final configService = ConfigService();

      // Initially not in demo mode
      expect(configService.isDemoMode, isFalse);

      configService.enableDemoMode();
      expect(configService.isDemoMode, isTrue);
    });

    test('ConfigService should provide demo user ID', () {
      final configService = ConfigService();

      final userId = configService.getDemoUserId();
      expect(userId, isNotEmpty);
      expect(userId, startsWith('demo_user_'));
    });

    test('ConfigService should show demo warning when appropriate', () {
      final configService = ConfigService();

      // The warning behavior depends on platform
      if (kIsWeb) {
        // On web, should never show warning because it's designed for web
        expect(configService.shouldShowDemoWarning(), isFalse);
      } else {
        // Initially should not show warning (demo mode is false)
        expect(configService.shouldShowDemoWarning(), isFalse);

        // After enabling demo mode, should show warning (on non-web with Firestore unavailable)
        configService.enableDemoMode();
        expect(configService.shouldShowDemoWarning(), isTrue);
      }

      // Test that enableDemoMode actually enables demo mode
      configService.enableDemoMode();
      expect(configService.isDemoMode, isTrue);
    });
  });
}