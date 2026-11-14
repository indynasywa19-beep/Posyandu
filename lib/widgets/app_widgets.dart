import 'package:flutter/material.dart';

import 'app_nav.dart';
import 'design_tokens.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Keluar akun',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.logoutBackground,
        foregroundColor: AppColors.logoutForeground,
      ),
      icon: const Icon(Icons.logout_rounded, size: 22),
    );
  }
}

/// Navigasi bawah untuk Orang Tua (5 tab) dan, bila [isKader] true, varian
/// Kader dengan aksi "Catat gizi" di tengah. Nama dan parameter tidak berubah
/// agar semua halaman pemanggil tetap berfungsi.
class AppBottomNav extends StatelessWidget {
  final bool isKader;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.isKader,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _parentItems = <NavDestination>[
    NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    NavDestination(
      icon: Icons.child_care_outlined,
      selectedIcon: Icons.child_care_rounded,
      label: 'Anak',
    ),
    NavDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Jadwal',
    ),
    NavDestination(
      icon: Icons.article_outlined,
      selectedIcon: Icons.article_rounded,
      label: 'Artikel',
    ),
    NavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  static const _kaderItems = <NavDestination>[
    NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    NavDestination(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Anak',
    ),
    NavDestination(
      icon: Icons.edit_note_rounded,
      selectedIcon: Icons.edit_note_rounded,
      label: 'Catat gizi',
    ),
    NavDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Jadwal',
    ),
    NavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = RolePalette.of(isKader);
    final items = isKader ? _kaderItems : _parentItems;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            return Expanded(
              child: AppNavTile(
                destination: items[index],
                selected: index == selectedIndex,
                palette: palette,
                emphasized: isKader && index == 2,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}
