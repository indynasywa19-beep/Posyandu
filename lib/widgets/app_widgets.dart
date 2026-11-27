import 'package:flutter/material.dart';

import 'app_nav.dart';
import 'design_tokens.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool inverted;

  const LogoutButton({super.key, required this.onPressed, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    if (inverted) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: IconButton(
          tooltip: 'Keluar akun',
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.white),
        ),
      );
    }

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

/// Navigasi bawah untuk Orang Tua (5 tab: Beranda, Anak, Jadwal, Riwayat, Profil).
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
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Anak',
    ),
    NavDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Jadwal',
    ),
    NavDestination(
      icon: Icons.access_time_rounded,
      selectedIcon: Icons.access_time_filled_rounded,
      label: 'Riwayat',
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
