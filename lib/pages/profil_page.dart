import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'artikel_page.dart';
import 'data_anak_page.dart';
import 'home_kader_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'pemeriksaan_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  User? get _user {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    final user = _user;
    final metadataName =
        user?.userMetadata?['display_name'] ?? user?.userMetadata?['full_name'];

    if (metadataName is String) {
      _nameController.text = metadataName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOGIKA AKUN & AUTENTIKASI (Logika Supabase tidak diubah)
  // ===========================================================================
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Nama lengkap tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'display_name': name}),
      );

      _showMessage('Profil berhasil diperbarui.');
    } catch (error) {
      _showMessage(
        friendlyError(
          error,
          fallback: 'Gagal memperbarui profil. Periksa koneksi internet Anda.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu memasukkan email dan kata sandi lagi untuk masuk.',
      confirmLabel: 'Keluar',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      _showMessage(
        friendlyError(
          error,
          fallback: 'Gagal keluar dari akun. Coba lagi.',
        ),
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppStatus.danger.foreground : null,
        ),
      );
  }

  // ===========================================================================
  // NAVIGASI
  // ===========================================================================
  void _onParentTabSelected(int index) {
    if (index == 4) return;
    final page = switch (index) {
      0 => const HomeOrtuPage(),
      1 => const DataAnakPage(),
      2 => const JadwalPage(),
      3 => const ArtikelPage(),
      _ => null,
    };

    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  void _onKaderTabSelected(int index) {
    if (index == 3) return;
    final page = switch (index) {
      0 => const HomeKaderPage(),
      1 => const DataAnakPage(isKader: true),
      2 => const JadwalPage(isKader: true),
      _ => null,
    };

    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  // ===========================================================================
  // FORM & KONTEN PROFIL (Satu arsitektur terpadu untuk kedua peran)
  // ===========================================================================
  Widget _buildProfileBody(BuildContext context, {
    required bool isKader,
    required String email,
    required RolePalette palette,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.page,
        AppSpace.md,
        AppSpace.page,
        AppSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KARTU HERO PROFIL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.xl),
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: AppRadius.cardAll,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  _nameController.text.trim().isEmpty
                      ? (isKader ? 'Kader Posyandu' : 'Orang Tua / Wali')
                      : _nameController.text.trim(),
                  textAlign: TextAlign.center,
                  style: AppText.title.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  isKader ? 'Kader Posyandu Aktif' : 'Orang Tua / Wali Balita',
                  style: AppText.caption.copyWith(
                    color: isKader ? AppColors.kaderMid : AppColors.parentTint,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.xl),

          // JUDUL SEKSI
          Text('Informasi Akun', style: AppText.title),
          const SizedBox(height: AppSpace.md),

          // INPUT NAMA LENGKAP
          AppTextField(
            label: 'Nama Lengkap',
            controller: _nameController,
            hint: 'Masukkan nama lengkap',
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: AppSpace.md),

          // INFORMASI EMAIL
          AppCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    borderRadius: AppRadius.controlAll,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: palette.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email Akun', style: AppText.caption),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // INFORMASI PERAN
          AppCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    borderRadius: AppRadius.controlAll,
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    color: palette.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Peran Akun', style: AppText.caption),
                      const SizedBox(height: 2),
                      Text(
                        isKader ? 'Kader Posyandu' : 'Orang Tua / Wali',
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: isKader ? 'Kader' : 'Orang Tua',
                  status: isKader ? AppStatus.info : AppStatus.neutral,
                  showIcon: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.xl),

          // TOMBOL SIMPAN
          AppButton(
            label: 'Simpan Profil',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _saveProfile,
          ),

          const SizedBox(height: AppSpace.md),

          // CATATAN BANTUAN
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.tint,
              borderRadius: AppRadius.controlAll,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: palette.primary,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'Pastikan informasi profil sudah sesuai agar data pelayanan dan kegiatan Posyandu tercatat dengan benar.',
                    style: AppText.caption.copyWith(
                      color: AppColors.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final email = user?.email ?? '-';
    final isKader = email.toLowerCase() == 'kader@gmail.com';
    final palette = RolePalette.of(isKader);

    if (isKader) {
      return Theme(
        data: AppTheme.kader,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Profil Saya'),
            actions: [
              KaderLogoutButton(onPressed: _logout),
              const SizedBox(width: AppSpace.sm),
            ],
          ),
          floatingActionButton: KaderCenterFab(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PemeriksaanPage(openFormOnStart: true),
                ),
              );
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: KaderBottomAppBar(
            selectedIndex: 3,
            onTabSelected: _onKaderTabSelected,
          ),
          body: _buildProfileBody(
            context,
            isKader: true,
            email: email,
            palette: palette,
          ),
        ),
      );
    }

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Saya'),
          actions: [
            LogoutButton(onPressed: _logout),
            const SizedBox(width: AppSpace.sm),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 4,
          onTap: _onParentTabSelected,
        ),
        body: _buildProfileBody(
          context,
          isKader: false,
          email: email,
          palette: palette,
        ),
      ),
    );
  }
}
