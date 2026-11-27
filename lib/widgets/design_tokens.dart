import 'package:flutter/material.dart';

/// Token desain SI-Posyandu.
///
/// Dua peran (Orang Tua dan Kader) punya identitas warna sendiri, tetapi
/// keduanya dibangun dari token yang sama: netral, status, spacing, radius,
/// dan tipografi. Dokumentasi lengkap ada di design.md.
///
/// Semua nama lama di [AppColors] dipertahankan supaya halaman yang belum
/// dimigrasi tetap berjalan.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // TEMA SI-POSYANDU: Biru Navy Gelap solid
  // ---------------------------------------------------------------------------
  static const navy = Color(0xFF0D3B66);
  static const primaryNavy = Color(0xFF0D3B66);

  // Logo Brand Colors
  static const logoBlue = Color(0xFF155EEF);
  static const logoGreen = Color(0xFF15803D);
  static const logoYellow = Color(0xFFF59E0B);

  // ORANG TUA: Biru Navy Gelap
  static const parent = Color(0xFF0D3B66);
  static const parentSoft = Color(0xFFEFF6FF);
  static const parentMid = Color(0xFFDBEAFE);
  static const parentTint = Color(0xFFE2E8F0);

  // KADER: Biru Navy Gelap
  static const kader = Color(0xFF0D3B66);
  static const kaderSoft = Color(0xFFEFF6FF);
  static const kaderMid = Color(0xFFDBEAFE);
  static const kaderTint = Color(0xFF194A7A);

  // ---------------------------------------------------------------------------
  // NETRAL (dipakai kedua peran)
  // ---------------------------------------------------------------------------
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;

  /// Teks utama.
  static const text = Color(0xFF0F172A);
  static const textNavy = Color(0xFF0D3B66);

  /// Teks sekunder.
  static const secondaryText = Color(0xFF64748B);

  /// Hint/placeholder dan label nav nonaktif.
  static const mutedText = Color(0xFF94A3B8);

  static const divider = Color(0xFFE2E8F0);
  static const border = Color(0xFFE2E8F0);

  // ---------------------------------------------------------------------------
  // KELUAR AKUN
  // ---------------------------------------------------------------------------
  static const logoutBackground = Color(0xFFFFE4E6);
  static const logoutForeground = Color(0xFFBE123C);

  // ---------------------------------------------------------------------------
  // PASANGAN WARNA AVATAR INISIAL (latar, teks). Semua kontras >= 6:1.
  // ---------------------------------------------------------------------------
  static const avatarPairs = <(Color, Color)>[
    (Color(0xFFDBEAFE), Color(0xFF0D3B66)),
    (Color(0xFFDCFCE7), Color(0xFF15803D)),
    (Color(0xFFFEF3C7), Color(0xFFB45309)),
    (Color(0xFFE0E7FF), Color(0xFF3730A3)),
    (Color(0xFFF1F5F9), Color(0xFF334155)),
    (Color(0xFFFFEDD5), Color(0xFF9A3412)),
  ];
}

/// Warna status. Selalu dipasangkan dengan ikon dan teks, jangan hanya warna.
enum AppStatus {
  success(
    foreground: Color(0xFF15803D),
    background: Color(0xFFDCFCE7),
    icon: Icons.check_circle_outline_rounded,
  ),
  warning(
    foreground: Color(0xFFB45309),
    background: Color(0xFFFEF3C7),
    icon: Icons.warning_amber_rounded,
  ),
  danger(
    foreground: Color(0xFFBE123C),
    background: Color(0xFFFFE4E6),
    icon: Icons.error_outline_rounded,
  ),
  info(
    foreground: Color(0xFF0D3B66),
    background: Color(0xFFDBEAFE),
    icon: Icons.info_outline_rounded,
  ),
  neutral(
    foreground: Color(0xFF475569),
    background: Color(0xFFF1F5F9),
    icon: Icons.circle_outlined,
  );

  const AppStatus({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
}

/// Warna per peran. Dipakai oleh [AppTheme] dan komponen reusable.
@immutable
class RolePalette {
  final Color primary;
  final Color onPrimary;

  /// Latar lembut untuk area terpilih, ikon, dan chip.
  final Color tint;

  /// Latar halaman.
  final Color background;

  const RolePalette({
    required this.primary,
    required this.onPrimary,
    required this.tint,
    required this.background,
  });

  static const parent = RolePalette(
    primary: AppColors.parent,
    onPrimary: Colors.white,
    tint: AppColors.parentTint,
    background: AppColors.background,
  );

  static const kader = RolePalette(
    primary: AppColors.kader,
    onPrimary: Colors.white,
    tint: AppColors.kaderMid,
    // Latar halaman Kader sengaja masih sama dengan Orang Tua (perilaku lama).
    // Akan ditinjau ulang saat beranda Kader dimigrasi.
    background: AppColors.background,
  );

  static RolePalette of(bool isKader) => isKader ? kader : parent;
}

/// Skala spacing 4/8.
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margin horizontal standar halaman.
  static const double page = 20;
}

/// Radius. Skala teratur untuk berbagai komponen.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Tombol, input, chip persegi, dialog kecil.
  static const double control = 12;

  /// Kartu, bottom sheet, dialog.
  static const double card = 16;

  /// Pil dan avatar.
  static const double pill = 999;

  static BorderRadius get controlAll => BorderRadius.circular(control);
  static BorderRadius get cardAll => BorderRadius.circular(card);
}

/// Ukuran minimum area sentuh (Material: 48 dp).
abstract final class AppSize {
  static const double touch = 48;
}
