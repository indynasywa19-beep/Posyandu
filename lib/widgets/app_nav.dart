import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'design_tokens.dart';

/// Satu tujuan di bilah navigasi bawah.
@immutable
class NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Satu item di bilah navigasi bawah, dipakai bersama oleh navigasi
/// Orang Tua dan Kader.
///
/// Tab terpilih ditandai tiga hal sekaligus: pil berlatar tint, ikon terisi
/// (bukan garis), dan label tebal. Jadi tidak bergantung pada warna saja.
/// Label minimal 12 sp, area sentuh minimal 48 dp.
class AppNavTile extends StatelessWidget {
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final RolePalette palette;

  /// Item aksi utama (misalnya "Catat gizi"): pil terisi penuh dengan
  /// warna utama.
  final bool emphasized;

  const AppNavTile({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.palette,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected || emphasized;
    final color = active ? palette.primary : AppColors.mutedText;

    final Color pillColor;
    final Color iconColor;
    if (emphasized) {
      pillColor = palette.primary;
      iconColor = palette.onPrimary;
    } else if (selected) {
      pillColor = palette.tint;
      iconColor = palette.primary;
    } else {
      pillColor = Colors.transparent;
      iconColor = AppColors.mutedText;
    }

    return Semantics(
      excludeSemantics: true,
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.controlAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touch),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 56,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
