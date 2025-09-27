import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing environment variables and configuration
class EnvironmentService {
  static final EnvironmentService _instance = EnvironmentService._internal();
  factory EnvironmentService() => _instance;
  EnvironmentService._internal();

  bool _isInitialized = false;

  /// Initialize the environment service
  /// Call this early in main() before runApp()
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      _instance._isInitialized = true;
      if (kDebugMode) {
        print('Environment variables loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not load .env file: $e');
        print('Using fallback configuration values');
      }
      _instance._isInitialized = false;
    }
  }

  /// Get environment variable with optional fallback
  String _getEnv(String key, [String fallback = '']) {
    if (!_isInitialized) return fallback;
    return dotenv.env[key] ?? fallback;
  }

  /// Get boolean environment variable
  bool _getBoolEnv(String key, [bool fallback = false]) {
    final value = _getEnv(key);
    if (value.isEmpty) return fallback;
    return value.toLowerCase() == 'true';
  }

  /// Get double environment variable
  double _getDoubleEnv(String key, [double fallback = 0.0]) {
    final value = _getEnv(key);
    if (value.isEmpty) return fallback;
    return double.tryParse(value) ?? fallback;
  }

  // Stripe Configuration
  String get stripePublishableKeyWeb => _getEnv(
    kReleaseMode ? 'STRIPE_LIVE_PUBLISHABLE_KEY_WEB' : 'STRIPE_PUBLISHABLE_KEY_WEB',
    'pk_test_your_publishable_key_here'
  );

  String get stripePublishableKeyMobile => _getEnv(
    kReleaseMode ? 'STRIPE_LIVE_PUBLISHABLE_KEY_MOBILE' : 'STRIPE_PUBLISHABLE_KEY_MOBILE',
    'pk_test_your_publishable_key_here'
  );

  String get stripeSecretKey => _getEnv(
    kReleaseMode ? 'STRIPE_LIVE_SECRET_KEY' : 'STRIPE_SECRET_KEY',
    'sk_test_your_secret_key_here'
  );

  /// Get the appropriate Stripe publishable key based on platform
  String get currentStripePublishableKey => kIsWeb
    ? stripePublishableKeyWeb
    : stripePublishableKeyMobile;

  // WooCommerce Configuration
  String get wooCommerceUrl => _getEnv('WOOCOMMERCE_URL', 'https://your-store.com/wp-json/wc/v3');
  String get wooCommerceConsumerKey => _getEnv('WOOCOMMERCE_CONSUMER_KEY');
  String get wooCommerceConsumerSecret => _getEnv('WOOCOMMERCE_CONSUMER_SECRET');

  // Firebase API Keys
  String get firebaseApiKeyWeb => _getEnv('FIREBASE_API_KEY_WEB');
  String get firebaseApiKeyAndroid => _getEnv('FIREBASE_API_KEY_ANDROID');
  String get firebaseApiKeyIOS => _getEnv('FIREBASE_API_KEY_IOS');

  // API Configuration
  String get baseUrl => _getEnv('BASE_URL', 'https://your-api-domain.com');
  String get googleMapsApiKey => _getEnv('GOOGLE_MAPS_API_KEY');
  String get sendgridApiKey => _getEnv('SENDGRID_API_KEY');

  // App Configuration
  String get appName => _getEnv('APP_NAME', 'WaterFilterNet');
  String get appVersion => _getEnv('APP_VERSION', '1.0.0');
  String get supportEmail => _getEnv('SUPPORT_EMAIL', 'support@waterfilternet.com');

  // Feature Flags
  bool get enableAnalytics => _getBoolEnv('ENABLE_ANALYTICS', true);
  bool get enableCrashlytics => _getBoolEnv('ENABLE_CRASHLYTICS', true);
  bool get enablePerformanceMonitoring => _getBoolEnv('ENABLE_PERFORMANCE_MONITORING', true);

  // Demo Mode Flag
  bool get forceDemoMode => _getBoolEnv('FORCE_DEMO_MODE', false);

  // Business Configuration
  double get freeShippingThreshold => _getDoubleEnv('FREE_SHIPPING_THRESHOLD', 75.0);
  String get defaultCurrency => _getEnv('DEFAULT_CURRENCY', 'EUR');
  String get defaultCountry => _getEnv('DEFAULT_COUNTRY', 'CY');

  // Validation flags
  bool get isStripeConfigured => currentStripePublishableKey.isNotEmpty &&
                                !currentStripePublishableKey.contains('your_');
  bool get isWooCommerceConfigured => wooCommerceConsumerKey.isNotEmpty &&
                                     wooCommerceConsumerSecret.isNotEmpty;
  bool get isGoogleMapsConfigured => googleMapsApiKey.isNotEmpty;

  /// Print configuration summary (debug mode only)
  void printConfigSummary() {
    if (!kDebugMode) return;

    print('\n=== Environment Configuration ===');
    print('Environment loaded: $_isInitialized');
    print('Build mode: ${kReleaseMode ? "Release" : "Debug"}');
    print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('App: $appName v$appVersion');
    print('Support Email: $supportEmail');
    print('Base URL: $baseUrl');
    print('Default Currency: $defaultCurrency');
    print('Free Shipping Threshold: €${freeShippingThreshold.toStringAsFixed(2)}');

    print('\n--- Service Status ---');
    print('Stripe configured: $isStripeConfigured');
    print('WooCommerce configured: $isWooCommerceConfigured');
    print('Google Maps configured: $isGoogleMapsConfigured');

    print('\n--- Feature Flags ---');
    print('Analytics: $enableAnalytics');
    print('Crashlytics: $enableCrashlytics');
    print('Performance Monitoring: $enablePerformanceMonitoring');
    print('================================\n');
  }

  /// Check if all required services are configured
  bool get allServicesConfigured => isStripeConfigured;

  /// Get warnings for unconfigured services
  List<String> get configurationWarnings {
    final warnings = <String>[];

    if (!isStripeConfigured) {
      warnings.add('Stripe payment processing is not configured');
    }

    if (!isWooCommerceConfigured) {
      warnings.add('WooCommerce integration is not configured (optional)');
    }

    if (!isGoogleMapsConfigured) {
      warnings.add('Google Maps is not configured (optional)');
    }

    return warnings;
  }
}