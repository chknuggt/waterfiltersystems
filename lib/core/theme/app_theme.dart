import 'package:flutter/material.dart';

class AppTheme {
  // Color constants inspired by skroutz.gr and water filtration theme
  static const Color primaryTeal = Color(0xFF00A693);
  static const Color primaryTealLight = Color(0xFF4DD8C5);
  static const Color primaryTealDark = Color(0xFF007768);

  static const Color secondaryBlue = Color(0xFF0066CC);
  static const Color accentOrange = Color(0xFFFF6B35);

  // Neutral colors for modern, clean design
  static const Color neutralGray50 = Color(0xFFF8F9FA);
  static const Color neutralGray100 = Color(0xFFF1F3F4);
  static const Color neutralGray200 = Color(0xFFE8EAED);
  static const Color neutralGray300 = Color(0xFFDADCE0);
  static const Color neutralGray400 = Color(0xFFBDC1C6);
  static const Color neutralGray500 = Color(0xFF9AA0A6);
  static const Color neutralGray600 = Color(0xFF80868B);
  static const Color neutralGray700 = Color(0xFF5F6368);
  static const Color neutralGray800 = Color(0xFF3C4043);
  static const Color neutralGray900 = Color(0xFF202124);

  // Success, warning, error colors
  static const Color successGreen = Color(0xFF34A853);
  static const Color warningAmber = Color(0xFFFBBC04);
  static const Color errorRed = Color(0xFFEA4335);

  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: primaryTeal,
      onPrimary: Colors.white,
      secondary: secondaryBlue,
      onSecondary: Colors.white,
      tertiary: accentOrange,
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: neutralGray900,
      surfaceContainerHighest: neutralGray50,
      surfaceContainer: neutralGray100,
      outline: neutralGray300,
      error: errorRed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Poppins',

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: neutralGray900,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralGray900,
          fontFamily: 'Poppins',
        ),
      ),

      // Card Theme - Skroutz-inspired
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: neutralGray400.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
      ),

      // Elevated Button Theme - Primary CTAs
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryTeal.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: primaryTeal,
        unselectedItemColor: neutralGray500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: neutralGray300,
        indicatorColor: primaryTeal.withOpacity(0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryTeal, size: 24);
          }
          return const IconThemeData(color: neutralGray500, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryTeal,
              fontFamily: 'Poppins',
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: neutralGray500,
            fontFamily: 'Poppins',
          );
        }),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralGray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: neutralGray500,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),

      // Text Themes
      textTheme: const TextTheme(
        // Headers
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: neutralGray900,
          fontFamily: 'Poppins',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: neutralGray900,
          fontFamily: 'Poppins',
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralGray900,
          fontFamily: 'Poppins',
        ),

        // Titles
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralGray900,
          fontFamily: 'Poppins',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralGray900,
          fontFamily: 'Poppins',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: neutralGray700,
          fontFamily: 'Poppins',
        ),

        // Body text
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: neutralGray800,
          fontFamily: 'Poppins',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: neutralGray700,
          fontFamily: 'Poppins',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: neutralGray600,
          fontFamily: 'Poppins',
        ),

        // Labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: neutralGray700,
          fontFamily: 'Poppins',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: neutralGray600,
          fontFamily: 'Poppins',
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: neutralGray500,
          fontFamily: 'Poppins',
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: neutralGray100,
        selectedColor: primaryTeal.withOpacity(0.12),
        disabledColor: neutralGray100,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: neutralGray700,
          fontFamily: 'Poppins',
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTeal,
          fontFamily: 'Poppins',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        pressElevation: 1,
      ),
    );
  }
}

// Custom text styles for specific use cases
class AppTextStyles {
  // Price displays - prominent and bold
  static const TextStyle priceText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppTheme.primaryTeal,
    fontFamily: 'Poppins',
  );

  static const TextStyle priceCurrency = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryTeal,
    fontFamily: 'Poppins',
  );

  // Product card text styles
  static const TextStyle productTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.neutralGray900,
    fontFamily: 'Poppins',
  );

  static const TextStyle productDescription = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.neutralGray700,
    fontFamily: 'Poppins',
  );

  static const TextStyle productRating = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.neutralGray600,
    fontFamily: 'Poppins',
  );

  // Section headers
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppTheme.neutralGray900,
    fontFamily: 'Poppins',
  );

  // Filter chip text
  static const TextStyle filterChipText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.neutralGray700,
    fontFamily: 'Poppins',
  );

  static const TextStyle filterChipSelectedText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryTeal,
    fontFamily: 'Poppins',
  );
}

// Common spacing and sizing constants
class AppSizing {
  // Border radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // Padding and margins
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
  static const double paddingXXLarge = 24.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
}