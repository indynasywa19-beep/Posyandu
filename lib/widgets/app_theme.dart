import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Gaya teks bernama. Satu keluarga font (Nunito) untuk seluruh aplikasi.
/// Ukuran terkecil 12 sp.
abstract final class AppText {
  static TextStyle _n(double size, FontWeight w, {double? height, Color? color}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: w,
        height: height,
        color: color ?? AppColors.text,
      );

  static TextStyle get headline => _n(24, FontWeight.w800, height: 1.25);
  static TextStyle get title => _n(20, FontWeight.w800, height: 1.3);
  static TextStyle get subtitle => _n(16, FontWeight.w700, height: 1.35);
  static TextStyle get body => _n(14, FontWeight.w500, height: 1.5);
  static TextStyle get bodyLarge => _n(16, FontWeight.w500, height: 1.5);
  static TextStyle get label => _n(14, FontWeight.w800, height: 1.3);
  static TextStyle get caption =>
      _n(12, FontWeight.w600, height: 1.4, color: AppColors.secondaryText);
}

abstract final class AppTheme {
  static ThemeData get parent => _build(RolePalette.parent);

  static ThemeData get kader => _build(RolePalette.kader);

  static ThemeData forRole({required bool isKader}) => isKader ? kader : parent;

  static ThemeData _build(RolePalette role) {
    final scheme = ColorScheme.fromSeed(
      seedColor: role.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: role.primary,
      onPrimary: role.onPrimary,
      primaryContainer: role.tint,
      onPrimaryContainer: AppColors.text,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.secondaryText,
      outline: AppColors.divider,
      outlineVariant: AppColors.divider,
      error: AppStatus.danger.foreground,
      onError: Colors.white,
      errorContainer: AppStatus.danger.background,
      onErrorContainer: AppStatus.danger.foreground,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: role.background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
        .copyWith(
          headlineSmall: AppText.headline,
          titleLarge: AppText.title,
          titleMedium: AppText.subtitle,
          titleSmall: AppText.label,
          bodyLarge: AppText.bodyLarge,
          bodyMedium: AppText.body,
          bodySmall: AppText.caption,
          labelLarge: AppText.label,
          labelMedium: AppText.caption.copyWith(fontWeight: FontWeight.w700),
          labelSmall: AppText.caption,
        );

    final controlShape = RoundedRectangleBorder(
      borderRadius: AppRadius.controlAll,
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: role == RolePalette.kader
            ? AppColors.surface
            : AppColors.navy,
        foregroundColor: role == RolePalette.kader
            ? AppColors.text
            : Colors.white,
        iconTheme: IconThemeData(
          color: role == RolePalette.kader
              ? AppColors.text
              : Colors.white,
        ),
        titleTextStyle: AppText.title.copyWith(
          color: role == RolePalette.kader
              ? AppColors.text
              : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: role == RolePalette.kader
            ? const Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              )
            : null,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: const BorderSide(color: AppColors.divider),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 14,
        ),
        hintStyle: AppText.body.copyWith(color: AppColors.mutedText),
        labelStyle: AppText.body.copyWith(color: AppColors.secondaryText),
        helperStyle: AppText.caption,
        errorStyle: AppText.caption.copyWith(
          color: AppStatus.danger.foreground,
          fontWeight: FontWeight.w700,
        ),
        border: border(AppColors.divider),
        enabledBorder: border(AppColors.divider),
        focusedBorder: border(role.primary, 2),
        errorBorder: border(AppStatus.danger.foreground),
        focusedErrorBorder: border(AppStatus.danger.foreground, 2),
        disabledBorder: border(AppColors.divider),
      ),

      // Lebar penuh sebagai bawaan (perilaku lama dipertahankan).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: role.primary,
          foregroundColor: role.onPrimary,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.mutedText,
          shape: controlShape,
          minimumSize: const Size(double.infinity, AppSize.touch),
          textStyle: AppText.label,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: role.primary,
          side: BorderSide(color: role.primary),
          shape: controlShape,
          minimumSize: const Size(64, AppSize.touch),
          textStyle: AppText.label,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: role.primary,
          minimumSize: const Size(64, AppSize.touch),
          textStyle: AppText.label,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSize.touch, AppSize.touch),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: role.tint,
        selectedColor: role.primary,
        labelStyle: AppText.caption.copyWith(
          color: role.primary,
          fontWeight: FontWeight.w800,
        ),
        secondaryLabelStyle: AppText.caption.copyWith(
          color: role.onPrimary,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
        titleTextStyle: AppText.title,
        contentTextStyle: AppText.body,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: role.primary),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: AppText.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
    );
  }
}
