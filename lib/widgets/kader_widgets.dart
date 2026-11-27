import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_components.dart';
import 'app_dialogs.dart';
import 'app_nav.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'design_tokens.dart';
import '../utils/app_copy.dart';
import '../pages/data_anak_page.dart';
import '../pages/home_kader_page.dart';
import '../pages/imunisasi_page.dart';
import '../pages/jadwal_page.dart';
import '../pages/login_page.dart';
import '../pages/pemeriksaan_page.dart';
import '../pages/profil_page.dart';
import '../pages/riwayat_page.dart';

/// Reusable widgets specifically crafted for the KADER role interface.
/// Preserves separation from Orang Tua widgets to avoid any regression.

// =============================================================================
// KADER WEB SCAFFOLD (Sidebar tetap kiri + Header + Konten + Footer)
// =============================================================================

class KaderWebScaffold extends StatelessWidget {
  /// 0: Beranda, 1: Monitoring Anak, 2: Pencatatan Gizi, 3: Input Imunisasi,
  /// 4: Jadwal Posyandu, 5: Riwayat Global, 6: Profil
  final int activeIndex;
  final String breadcrumb;
  final Widget body;
  final Widget? floatingActionButton;

  const KaderWebScaffold({
    super.key,
    required this.activeIndex,
    required this.breadcrumb,
    required this.body,
    this.floatingActionButton,
  });

  static const _navItems = [
    (Icons.home_outlined, 'Beranda'),
    (Icons.people_outline_rounded, 'Monitoring Anak'),
    (Icons.monitor_weight_outlined, 'Pencatatan Gizi'),
    (Icons.colorize_outlined, 'Input Imunisasi'),
    (Icons.calendar_today_outlined, 'Jadwal Posyandu'),
    (Icons.history_rounded, 'Riwayat Global'),
    (Icons.person_outline_rounded, 'Profil'),
  ];

  void _navigateTo(BuildContext context, int index, {bool fromDrawer = false}) {
    if (fromDrawer) {
      Navigator.pop(context);
    }
    if (index == activeIndex) return;

    final Widget page = switch (index) {
      0 => const HomeKaderPage(),
      1 => const DataAnakPage(isKader: true),
      2 => const PemeriksaanPage(),
      3 => const ImunisasiPage(),
      4 => const JadwalPage(isKader: true),
      5 => const RiwayatPage(isKader: true),
      6 => const ProfilPage(isKader: true),
      _ => const HomeKaderPage(),
    };

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk membuka SI-POSYANDU.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(
              error,
              fallback: 'Belum bisa keluar dari akun. Coba lagi.',
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSidebarContent(BuildContext context, {bool fromDrawer = false}) {
    final user = Supabase.instance.client.auth.currentUser;
    final kaderName = displayNameFromUser(user, fallback: 'Kader Posyandu');
    final kaderPosyandu =
        (user?.userMetadata?['address']?.toString() ?? '').trim();

    Widget buildNavItem(int index) {
      final (icon, label) = _navItems[index];
      final isSelected = index == activeIndex;

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _navigateTo(context, index, fromDrawer: fromDrawer),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.78),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.body.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.88),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget sectionLabel(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        child: Text(
          title,
          style: AppText.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      );
    }

    return Container(
      width: 248,
      color: AppColors.navy,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Brand & Badge Kader
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SiPosyanduLogoIcon(size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PELAYANAN KESEHATAN TERPADU',
                              style: AppText.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              'SI-POSYANDU',
                              style: AppText.title.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const KaderBadge(),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.white.withValues(alpha: 0.14)),

            // Daftar Menu Terstruktur
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: [
                  sectionLabel('MENU UTAMA'),
                  buildNavItem(0), // Beranda
                  buildNavItem(1), // Monitoring Anak

                  sectionLabel('PELAYANAN & JADWAL'),
                  buildNavItem(2), // Pencatatan Gizi
                  buildNavItem(3), // Input Imunisasi
                  buildNavItem(4), // Jadwal Posyandu
                  buildNavItem(5), // Riwayat Global

                  sectionLabel('PENGATURAN'),
                  buildNavItem(6), // Profil
                ],
              ),
            ),

            // Kartu Info Kader & Tombol Keluar di Bagian Bawah
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(
                          kaderName.isNotEmpty
                              ? kaderName[0].toUpperCase()
                              : 'K',
                          style: AppText.label.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kaderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              kaderPosyandu.isEmpty
                                  ? 'Petugas Posyandu'
                                  : kaderPosyandu,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _logout(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Keluar akun',
                              style: AppText.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, {required bool isMobile}) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = displayNameFromUser(user, fallback: 'Kader');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';
    final now = DateTime.now();
    final periodeText = 'Periode: ${bulanLengkap(now.month)} ${now.year}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 60,
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
          child: Row(
            children: [
              if (isMobile) ...[
                Builder(
                  builder: (ctx) => IconButton(
                    tooltip: 'Menu Kader',
                    icon: const Icon(Icons.menu_rounded, color: AppColors.navy),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  isMobile ? _navItems[activeIndex].$2 : breadcrumb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 15 : 14,
                  ),
                ),
              ),
              if (!isMobile) ...[
                Text(
                  periodeText,
                  style: AppText.caption.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 16),
                Container(height: 20, width: 1, color: AppColors.divider),
                const SizedBox(width: 16),
              ],
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppText.label.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              flex: 75,
              child: Container(height: 2.5, color: AppColors.navy),
            ),
            Expanded(
              flex: 25,
              child: Container(height: 2.5, color: const Color(0xFF15803D)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isMobile = MediaQuery.sizeOf(context).width < 820;

    return Theme(
      data: AppTheme.kader,
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: floatingActionButton,
        drawer: isMobile
            ? Drawer(
                backgroundColor: AppColors.navy,
                child: _buildSidebarContent(context, fromDrawer: true),
              )
            : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isMobile) _buildSidebarContent(context),
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(context, isMobile: isMobile),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            body,
                            const SizedBox(height: AppSpace.xxl),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Text(
                                '© ${now.year} SI-POSYANDU · Kebijakan Privasi · Bantuan · Versi 1.0',
                                style: AppText.caption.copyWith(
                                  color: AppColors.mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


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
