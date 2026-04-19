import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────
/// PantryPal Design System
/// Mirrors: pp-frontend/src/index.css :root vars
/// Font: Matter (bundled TTF)
/// ──────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Core palette from pp-frontend CSS vars ──
  static const Color primary = Color(0xFF00C755);        // --pp-green / --primary
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFDCE9DD);      // --secondary / --pp-off-green
  static const Color background = Color(0xFFF8F7F2);     // landing page bg
  static const Color surface = Color(0xFFFFFFFF);         // --card
  static const Color foreground = Color(0xFF10120F);      // --pp-black / --foreground
  static const Color border = Color(0xFFE8EAEC);         // --border / --pp-grey
  static const Color destructive = Color(0xFFD9534F);    // --destructive
  static const Color muted = Color(0xFFDCE9DD);          // --muted
  static const Color ring = Color(0xFF00C755);           // --ring

  // ── Text ──
  static const Color textPrimary = Color(0xFF10120F);
  static const Color textSecondary = Color(0xFF5F645C);   // from landing page
  static const Color textHint = Color(0xFF9EA19B);        // muted-foreground approx
  static const Color textMuted = Color(0xFF7D8277);       // kicker color

  // ── Semantic ──
  static const Color error = Color(0xFFD9534F);
  static const Color warning = Color(0xFFF1C40F);
  static const Color success = Color(0xFF00C755);

  // ── Expiry Tags ──
  static const Color expiryExpired = Color(0xFFD9534F);
  static const Color expirySoon = Color(0xFFF39C12);
  static const Color expiryFresh = Color(0xFF00C755);

  // ── Dark surfaces (dashboard sidebar) ──
  static const Color darkSurface = Color(0xFF10120F);

  // ── Aliases (referenced across screens) ──
  static const Color surfaceTint = Color(0xFFF8F7F2);   // bg-like tint
  static const Color primaryLight = Color(0xFFDCE9DD);   // secondary/mint
  static const Color primaryDark = Color(0xFF0A9940);    // darker green
  static const Color accent = Color(0xFF00C755);         // same as primary
}

/// ──────────────────────────────────────────────
/// Typography — using bundled Matter font
/// ──────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Matter';

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: -2.0,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.2,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.8,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
        ),
      );
}

/// ──────────────────────────────────────────────
/// Theme Data
/// ──────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Matter',
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.primaryForeground,
          secondary: AppColors.secondary,
          onSecondary: AppColors.foreground,
          surface: AppColors.surface,
          onSurface: AppColors.foreground,
          error: AppColors.destructive,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTypography.textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Matter',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.foreground,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'Matter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.foreground,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'Matter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(
            fontFamily: 'Matter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelTextStyle: WidgetStatePropertyAll(
            const TextStyle(
              fontFamily: 'Matter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
