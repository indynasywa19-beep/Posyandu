import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_nav.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'design_tokens.dart';

/// Reusable widgets specifically crafted for the KADER role interface.
/// Preserves separation from Orang Tua widgets to avoid any regression.

class KaderBottomAppBar extends StatelessWidget {
  final int selectedIndex; // 0: Beranda, 1: Anak, 2: Jadwal, 3: Profil
  final ValueChanged<int> onTabSelected;

  /// Label di bawah tombol tengah. Harus sama dengan aksi tombol tengah
  /// ([KaderCenterFab]) di halaman yang memanggil.
  final String centerLabel;

  const KaderBottomAppBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.centerLabel = 'Catat gizi',
  });

  static const _beranda = NavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Beranda',
  );
  static const _anak = NavDestination(
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    label: 'Anak',
  );
  static const _jadwal = NavDestination(
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    label: 'Jadwal',
  );
  static const _profil = NavDestination(
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Profil',
  );

  @override
  Widget build(BuildContext context) {
    const palette = RolePalette.kader;

    Widget tile(NavDestination d, int index) => Expanded(
      child: AppNavTile(
        destination: d,
        selected: selectedIndex == index,
        palette: palette,
        onTap: () => onTabSelected(index),
      ),
    );

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      height: 72,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black38,
      elevation: 4,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          tile(_beranda, 0),
          tile(_anak, 1),
          // Ruang untuk tombol tengah yang menempel di takik. Labelnya ada di
          // sini karena tombol melayang (FAB) tidak punya label sendiri.
          SizedBox(
            width: 76,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerLabel,
                    maxLines: 1,
                    style: AppText.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          tile(_jadwal, 2),
          tile(_profil, 3),
        ],
      ),
    );
  }
}

class KaderCenterFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const KaderCenterFab({
    super.key,
    required this.onPressed,
    this.tooltip = 'Catat gizi',
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      shape: const CircleBorder(),
      backgroundColor: RolePalette.kader.primary,
      foregroundColor: RolePalette.kader.onPrimary,
      elevation: 3,
      child: const Icon(Icons.edit_note_rounded, size: 28),
    );
  }
}

/// Tombol keluar akun Kader. Memakai [LogoutButton] yang sama dengan
/// Orang Tua: area sentuh 48 dp dan ada tooltip/label untuk pembaca layar.
class KaderLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const KaderLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => LogoutButton(onPressed: onPressed);
}

/// Ringkasan di beranda Kader: tanggal, jumlah anak, dan aksi utama.
/// Datar, satu warna, tanpa dekorasi.
class KaderHeroCard extends StatelessWidget {
  final String dateLabel;
  final String countText;
  final VoidCallback onActionPressed;
  final String actionLabel;

  /// Bila diisi, tombol "Coba lagi" tampil di samping aksi utama.
  final VoidCallback? onRetry;

  const KaderHeroCard({
    super.key,
    required this.dateLabel,
    required this.countText,
    required this.onActionPressed,
    this.actionLabel = 'Mulai timbang',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const palette = RolePalette.kader;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl - 4),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: AppText.caption.copyWith(color: AppColors.kaderMid),
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              countText,
              style: AppText.title.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: onActionPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: palette.primary,
                  minimumSize: const Size(64, AppSize.touch),
                ),
                child: Text(actionLabel),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Coba lagi'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kolom cari yang membuka daftar anak. Ini tombol, bukan kolom isian,
/// jadi dilabeli sebagai tombol untuk pembaca layar.
class KaderSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback onTap;

  const KaderSearchBar({
    super.key,
    required this.hintText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hintText,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlAll,
          side: const BorderSide(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.secondaryText,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      hintText,
                      style: AppText.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class KaderTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final VoidCallback? onBack;

  const KaderTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          IconButton(
            tooltip: 'Kembali',
            onPressed: onBack ?? () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppText.title),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppText.caption),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class KaderInfoPill extends StatelessWidget {
  final IconData icon;
  final String message;

  const KaderInfoPill({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md + 2,
        vertical: AppSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.kaderSoft,
        borderRadius: AppRadius.controlAll,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.kader),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.caption.copyWith(
                color: AppColors.kader,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KaderChildSelectorTile extends StatelessWidget {
  final String childName;
  final String? subtitle;
  final VoidCallback onSelectChild;

  /// true bila belum ada anak yang dipilih (tampil ikon orang, bukan inisial).
  final bool placeholder;

  const KaderChildSelectorTile({
    super.key,
    required this.childName,
    this.subtitle,
    required this.onSelectChild,
    this.placeholder = false,
  });

  bool get _isPlaceholder => placeholder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actionLabel = _isPlaceholder ? 'Pilih' : 'Ganti';

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: _isPlaceholder
          ? 'Belum ada anak dipilih. Pilih anak'
          : '$childName${subtitle == null ? '' : ', $subtitle'}. Ganti anak',
      onTap: onSelectChild,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlAll,
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          onTap: onSelectChild,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm + 2,
              ),
              child: Row(
                children: [
                  if (_isPlaceholder)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_search_outlined,
                        color: scheme.primary,
                        size: 26,
                      ),
                    )
                  else
                    InitialsAvatar(name: childName, size: 44),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isPlaceholder ? 'Belum ada anak dipilih' : childName,
                          style: AppText.subtitle.copyWith(
                            color: _isPlaceholder
                                ? AppColors.secondaryText
                                : AppColors.text,
                          ),
                        ),
                        if (subtitle != null && !_isPlaceholder) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: AppText.caption),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    actionLabel,
                    style: AppText.caption.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
