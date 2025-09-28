import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/navigation/bottom_navigation.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/address/address_management_screen.dart';
import 'screens/payment/card_management_screen.dart';
import 'screens/order/order_success_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'core/theme/app_theme.dart';
import 'core/guards/admin_guard.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'services/payment_service.dart';
import 'services/config_service.dart';
import 'services/environment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables first
  try {
    await EnvironmentService.initialize();
    final envService = EnvironmentService();
    envService.printConfigSummary();
  } catch (e) {
    print('Environment initialization error: $e');
    // Continue execution - fallback values will be used
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue execution - the app can still work in demo mode
  }

  // Initialize configuration service (checks Firestore connectivity)
  try {
    final configService = ConfigService();
    await configService.initialize();
    print('Configuration service initialized');
    configService.logConfigState();
  } catch (e) {
    print('Config service initialization error: $e');
    // Continue execution - ConfigService will default to safe values
  }

  // Initialize Stripe
  try {
    await PaymentService.initializeStripe();
  } catch (e) {
    print('Stripe initialization error: $e');
    // Continue execution - the app can work without Stripe for demo purposes
  }

  runApp(const WaterFilterNetApp());
}

class WaterFilterNetApp extends StatelessWidget {
  const WaterFilterNetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WaterFilterNet',

        // Apply our custom Material 3 theme
        theme: AppTheme.lightTheme,

        // App metadata
        initialRoute: '/',

        routes: {
          '/': (context) => const AuthWrapper(),
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const NavigationMenu(),
          '/checkout': (context) => const CheckoutScreen(),
          '/address_management': (context) => const AddressManagementScreen(),
          '/card_management': (context) => const CardManagementScreen(),
          '/admin': (context) => const AdminGuard(child: AdminDashboard()),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/order_success':
              final orderId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => OrderSuccessScreen(orderId: orderId),
              );
            default:
              return null;
          }
        },

        // Handle unknown routes
        onUnknownRoute: (RouteSettings settings) {
          // Don't redirect admin routes to auth screen
          if (settings.name?.startsWith('/admin') == true) {
            return null; // Let onGenerateRoute handle admin routes
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (BuildContext context) => const AuthScreen(),
          );
        },

        // App lifecycle and performance
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling, // Prevent text scaling issues
            ),
            child: child!,
          );
        },
      ),
    );
  }

}

// Auth wrapper to check authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          // Show loading screen while checking auth state
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 80,
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Check authentication state
        if (authProvider.isAuthenticated) {
          return const NavigationMenu();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}