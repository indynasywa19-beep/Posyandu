import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData get parent =>
      _build(const Color(0xFF1261A0), const Color(0xFFF4F1FA));

  static ThemeData get kader => _build(AppColors.kader, AppColors.kaderSoft);

  static ThemeData _build(Color primary, Color soft) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F1FA),
    );

    final body = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFF123B5D),
      displayColor: const Color(0xFF123B5D),
    );

    return base.copyWith(
      textTheme: GoogleFonts.fredokaTextTheme(body).copyWith(
        bodyLarge: body.bodyLarge,
        bodyMedium: body.bodyMedium,
        bodySmall: body.bodySmall,
        labelLarge: body.labelLarge,
        labelMedium: body.labelMedium,
        labelSmall: body.labelSmall,
      ),

      // APP BAR
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F1FA),
        foregroundColor: Color(0xFF123B5D),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      // INPUT
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F1FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1261A0), width: 1.5),
        ),
      ),

      // BUTTON
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1261A0),
          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          minimumSize: const Size(double.infinity, 48),

          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),

      // OUTLINED BUTTON
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1261A0),

          side: const BorderSide(color: Color(0xFF1261A0)),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),

      // TEXT BUTTON
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1261A0),

          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),

      // PROGRESS INDICATOR
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF1261A0),
      ),

      // SNACKBAR
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF123B5D),
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
