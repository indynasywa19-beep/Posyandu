import 'package:flutter/material.dart';

abstract final class AppColors {
  // =========================================================
  // ORANG TUA
  // Konsep: Biru + Lavender Soft + Putih + Navy
  // =========================================================

  // Biru utama
  static const parent = Color(0xFF1261A0);

  // Lavender muda untuk background/area soft
  static const parentSoft = Color(0xFFF4F1FA);

  // Lavender soft untuk aksen/card
  static const parentMid = Color(0xFFA99BCF);

  // =========================================================
  // KADER
  // Tetap menggunakan konsep biru
  // =========================================================
  static const kader = Color(0xFF1D4ED8);
  static const kaderSoft = Color(0xFFEFF6FF);
  static const kaderMid = Color(0xFFDBEAFE);

  // =========================================================
  // TEXT
  // =========================================================

  // Navy untuk judul utama
  static const text = Color(0xFF123B5D);

  // Abu kebiruan untuk teks sekunder
  static const secondaryText = Color(0xFF64748B);

  // Border/divider
  static const divider = Color(0xFFE2E8F0);

  // =========================================================
  // LOGOUT
  // =========================================================

  static const logoutBackground = Color(0xFFFFE4E6);
  static const logoutForeground = Color(0xFFBE123C);

  // =========================================================
  // MENU BUBBLES
  // =========================================================
  // Tidak menggunakan hijau lagi.
  // Semua dibuat dalam kombinasi biru + lavender + soft neutral.
  static const menuBubbles = <(Color, Color)>[
    (Color(0xFFEAF3FA), Color(0xFF1261A0)),
    (Color(0xFFF4F1FA), Color(0xFFA99BCF)),
    (Color(0xFFE8EEF5), Color(0xFF123B5D)),
    (Color(0xFFF0EDF8), Color(0xFF8B7BB8)),
    (Color(0xFFEAF3FA), Color(0xFF1261A0)),
    (Color(0xFFF4F1FA), Color(0xFF7D6DA8)),
  ];
}
