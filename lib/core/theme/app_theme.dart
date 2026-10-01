import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Central theme. Large, readable typography with high contrast and
/// generous component sizing for a 60+ audience — while staying modern.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.baloo2(
          color: AppColors.ink,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
          textStyle: GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800),
          shape: const StadiumBorder(),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.45),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
          side: const BorderSide(color: AppColors.primary, width: 2),
          textStyle: GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md + 2,
        ),
        hintStyle: const TextStyle(color: AppColors.inkFaint, fontSize: 18),
        labelStyle: const TextStyle(color: AppColors.inkSoft, fontSize: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 2.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontSize: 17, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Baloo 2 (rounded, warm — matches the logo) for anything that sets the
  /// page's tone; Nunito (clean, high x-height) for running text people
  /// actually read at length.
  static TextTheme _textTheme(TextTheme base) {
    final body = GoogleFonts.nunitoTextTheme(base);
    return body
        .copyWith(
          displaySmall: GoogleFonts.baloo2(
            textStyle: base.displaySmall,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.15,
          ),
          headlineMedium: GoogleFonts.baloo2(
            textStyle: base.headlineMedium,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.2,
          ),
          headlineSmall: GoogleFonts.baloo2(
            textStyle: base.headlineSmall,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleLarge: GoogleFonts.baloo2(
            textStyle: base.titleLarge,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleMedium: GoogleFonts.baloo2(
            textStyle: base.titleMedium,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: GoogleFonts.nunito(
            textStyle: base.bodyLarge,
            fontSize: 18,
            color: AppColors.ink,
            height: 1.45,
          ),
          bodyMedium: GoogleFonts.nunito(
            textStyle: base.bodyMedium,
            fontSize: 17,
            color: AppColors.inkSoft,
            height: 1.45,
          ),
          labelLarge: GoogleFonts.nunito(
            textStyle: base.labelLarge,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        )
        .apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        );
  }
}
