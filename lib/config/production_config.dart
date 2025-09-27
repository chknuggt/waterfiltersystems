import 'package:flutter/foundation.dart';

/// Production configuration constants
class ProductionConfig {
  // Stripe Configuration - now handled by EnvironmentService
  // Use EnvironmentService().currentStripePublishableKey instead

  // API Configuration
  static const String baseUrl = 'https://your-api-domain.com';
  static const String wooCommerceUrl = 'https://your-store.com/wp-json/wc/v3';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePerformanceMonitoring = true;

  // App Configuration
  static const String appName = 'WaterFilterNet';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@waterfilternet.com';

  // Business Configuration
  static const double freeShippingThreshold = 75.0;
  static const String defaultCurrency = 'EUR';
  static const String defaultCountry = 'CY';

  // Validation Configuration
  static const int maxCartItems = 50;
  static const int maxAddresses = 10;
  static const int maxPaymentCards = 5;

  // Security Configuration
  static const int sessionTimeoutMinutes = 30;
  static const int maxLoginAttempts = 5;

  /// Check if the app is running in production mode
  static bool get isProduction => kReleaseMode;

  /// Check if debug features should be enabled
  static bool get enableDebugFeatures => kDebugMode;

  /// Get the appropriate Stripe key based on platform
  /// DEPRECATED: Use EnvironmentService().currentStripePublishableKey instead
  static String get currentStripeKey => 'DEPRECATED_USE_ENVIRONMENT_SERVICE';
}