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
  // ORANG TUA: biru + lavender lembut
  // ---------------------------------------------------------------------------
  static const parent = Color(0xFF1261A0);
  static const parentSoft = Color(0xFFF4F1FA);

  /// Lavender aksen. Jangan dipakai sebagai latar teks atau ikon biru
  /// (kontras hanya 2.5:1). Untuk pil terpilih pakai [parentTint].
  static const parentMid = Color(0xFFA99BCF);

  /// Latar pil/ikon terpilih untuk peran Orang Tua (kontras 5.5:1 dengan [parent]).
  static const parentTint = Color(0xFFE3EEF8);

  // ---------------------------------------------------------------------------
  // KADER: biru lebih tegas
  // ---------------------------------------------------------------------------
  static const kader = Color(0xFF1D4ED8);
  static const kaderSoft = Color(0xFFEFF6FF);

  /// Sekaligus latar pil terpilih untuk peran Kader (kontras 5.5:1 dengan [kader]).
  static const kaderMid = Color(0xFFDBEAFE);

  // ---------------------------------------------------------------------------
  // NETRAL (dipakai kedua peran)
  // ---------------------------------------------------------------------------
  static const background = Color(0xFFF4F1FA);
  static const surface = Colors.white;

  /// Teks utama. 11.6:1 di atas putih.
  static const text = Color(0xFF123B5D);

  /// Teks sekunder. Sebelumnya #64748B (4.26:1 di atas lavender, di bawah 4.5).
  /// Sekarang 5.6:1 di atas lavender dan 6.2:1 di atas putih.
  static const secondaryText = Color(0xFF526277);

  /// Hint/placeholder dan label nav nonaktif. 5.1:1 di atas putih.
  /// Menggantikan #94A3B8 yang hanya 2.6:1.
  static const mutedText = Color(0xFF5F6F82);

  static const divider = Color(0xFFE2E8F0);

  // ---------------------------------------------------------------------------
  // KELUAR AKUN (nama lama dipertahankan)
  // ---------------------------------------------------------------------------
  static const logoutBackground = Color(0xFFFFE4E6);
  static const logoutForeground = Color(0xFFBE123C);

  // ---------------------------------------------------------------------------
  // PASANGAN WARNA AVATAR INISIAL (latar, teks). Semua kontras >= 6:1.
  // ---------------------------------------------------------------------------
  static const avatarPairs = <(Color, Color)>[
    (Color(0xFFDCEBF7), Color(0xFF0F4C81)),
    (Color(0xFFE8E3F5), Color(0xFF4C3F82)),
    (Color(0xFFD5F0EC), Color(0xFF115E59)),
    (Color(0xFFFDE8D8), Color(0xFF9A3412)),
    (Color(0xFFF1E4FA), Color(0xFF6B21A8)),
    (Color(0xFFE2E8F0), Color(0xFF334155)),
  ];
}

/// Warna status. Selalu dipasangkan dengan ikon dan teks, jangan hanya warna.
enum AppStatus {
  success(
    foreground: Color(0xFF166534),
    background: Color(0xFFDCFCE7),
    icon: Icons.check_circle_outline_rounded,
  ),
  warning(
    foreground: Color(0xFF92400E),
    background: Color(0xFFFEF3C7),
    icon: Icons.warning_amber_rounded,
  ),
  danger(
    foreground: Color(0xFFBE123C),
    background: Color(0xFFFFE4E6),
    icon: Icons.error_outline_rounded,
  ),
  info(
    foreground: Color(0xFF075985),
    background: Color(0xFFE0F2FE),
    icon: Icons.info_outline_rounded,
  ),
  neutral(
    foreground: Color(0xFF475569),
    background: Color(0xFFEEF2F6),
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

/// Radius. Hanya dua nilai, ditambah pil.
abstract final class AppRadius {
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
