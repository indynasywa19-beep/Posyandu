import 'package:flutter/material.dart';

abstract final class AppColors {
  static const parent = Color(0xFF15803D);
  static const parentSoft = Color(0xFFECFDF3);
  static const parentMid = Color(0xFFD1FAE5);
  static const kader = Color(0xFF1D4ED8);
  static const kaderSoft = Color(0xFFEFF6FF);
  static const kaderMid = Color(0xFFDBEAFE);
  static const text = Color(0xFF0F172A);
  static const secondaryText = Color(0xFF475569);
  static const divider = Color(0xFFCBD5E1);
  static const logoutBackground = Color(0xFFFFE4E6);
  static const logoutForeground = Color(0xFFBE123C);

  static const menuBubbles = <(Color, Color)>[
    (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    (Color(0xFFFEF3C7), Color(0xFFB45309)),
    (Color(0xFFFFE4D6), Color(0xFFC2410C)),
    (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
    (Color(0xFFD1FAE5), Color(0xFF047857)),
    (Color(0xFFFCE7F3), Color(0xFFBE185D)),
  ];
}
