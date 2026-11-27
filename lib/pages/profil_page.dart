import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'data_anak_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'riwayat_page.dart';

class ProfilPage extends StatefulWidget {
  final bool? isKader;

  const ProfilPage({super.key, this.isKader});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isSaving = false;

  User? get _user {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _resolvedIsKader {
    if (widget.isKader != null) return widget.isKader!;
    final user = _user;
    final email = (user?.email ?? '').toLowerCase();
    final role = user?.userMetadata?['role']?.toString().toLowerCase();
    return email == 'kader@gmail.com' || role == 'kader';
  }

  @override
  void initState() {
    super.initState();

    final meta = _user?.userMetadata;
    final metadataName = meta?['display_name'] ?? meta?['full_name'];
    if (metadataName is String) {
      _nameController.text = metadataName;
    }

    final metadataPhone = meta?['phone'];
    if (metadataPhone is String) {
      _phoneController.text = metadataPhone;
    }

    final metadataAddress = meta?['address'];
    if (metadataAddress is String) {
      _addressController.text = metadataAddress;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOGIKA AKUN & AUTENTIKASI
  // ===========================================================================
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      _showMessage('Nama lengkap tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': name,
            'phone': phone,
            'address': address,
          },
        ),
      );

      // Sinkronkan nama & no_hp ke semua anak milik akun (satu KK) ini
      if (!_resolvedIsKader && user != null) {
        await supabase
            .from('anak')
            .update({
              'nama_ortu': name,
              'no_hp': phone,
            })
            .eq('user_id', user.id);
      }

      _showMessage('Profil & kontak keluarga berhasil diperbarui.');
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

  Future<void> _showChangePasswordDialog() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    bool saving = false;
    String? errorText;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Ubah Kata Sandi', style: AppText.title),
                      ),
                      IconButton(
                        onPressed: saving ? null : () => Navigator.pop(ctx, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan kata sandi baru minimal 6 karakter.',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi baru',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi kata sandi',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: AppText.caption.copyWith(
                        color: AppStatus.danger.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Simpan Kata Sandi',
                    isLoading: saving,
                    onPressed: () async {
                      final pass = passCtrl.text.trim();
                      final confirm = confirmCtrl.text.trim();
                      if (pass.length < 6) {
                        setDialogState(
                          () => errorText = 'Kata sandi minimal 6 karakter.',
                        );
                        return;
                      }
                      if (pass != confirm) {
                        setDialogState(
                          () => errorText = 'Konfirmasi kata sandi tidak cocok.',
                        );
                        return;
                      }

                      setDialogState(() {
                        saving = true;
                        errorText = null;
                      });

                      try {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(password: pass),
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          errorText = friendlyError(
                            e,
                            fallback: 'Gagal memperbarui kata sandi.',
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    passCtrl.dispose();
    confirmCtrl.dispose();

    if (updated == true && mounted) {
      _showMessage('Kata sandi berhasil diperbarui.');
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
      3 => const RiwayatPage(),
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
  // FORM & KONTEN PROFIL
  // ===========================================================================
  Widget _buildProfileContent(
    BuildContext context, {
    required bool isKader,
    required String email,
    required RolePalette palette,
  }) {
    final displayName = _nameController.text.trim().isEmpty
        ? (isKader ? 'Kader Posyandu' : 'Orang Tua / Wali')
        : _nameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KARTU HERO PROFIL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.xl),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(AppRadius.card),
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
                displayName,
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                isKader ? 'Kader Posyandu Aktif' : 'Orang Tua / Wali Balita',
                style: AppText.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.xl),

        // INFORMASI AKUN (READ-ONLY)
        Text('Informasi Akun', style: AppText.title),
        const SizedBox(height: AppSpace.md),

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
              StatusChip(
                label: isKader ? 'Kader' : 'Orang Tua',
                status: isKader ? AppStatus.info : AppStatus.neutral,
                showIcon: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.xl),

        // DATA DIRI YANG BISA DIEDIT
        Text('Data Pribadi', style: AppText.title),
        const SizedBox(height: AppSpace.md),

        AppTextField(
          label: 'Nama Lengkap',
          controller: _nameController,
          hint: 'Masukkan nama lengkap',
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: AppSpace.md),

        AppTextField(
          label: 'Nomor Telepon / WhatsApp',
          controller: _phoneController,
          hint: 'Contoh: 081234567890',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: AppSpace.md),

        AppTextField(
          label: isKader ? 'Wilayah Tugas / Nama Posyandu' : 'Alamat Rumah',
          controller: _addressController,
          hint: isKader
              ? 'Contoh: Posyandu Melati RW 03'
              : 'Contoh: Jl. Mawar No. 12, RT 02/03',
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: AppSpace.xl),

        AppButton(
          label: 'Simpan Perubahan',
          icon: Icons.save_outlined,
          isLoading: _isSaving,
          onPressed: _saveProfile,
        ),

        const SizedBox(height: AppSpace.xl),

        // KEAMANAN AKUN
        Text('Keamanan', style: AppText.title),
        const SizedBox(height: AppSpace.md),

        AppCard(
          onTap: _showChangePasswordDialog,
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
                  Icons.lock_outline_rounded,
                  color: palette.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubah Kata Sandi',
                      style: AppText.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Perbarui kata sandi untuk menjaga keamanan akun',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final email = user?.email ?? '-';
    final isKader = _resolvedIsKader;
    final palette = RolePalette.of(isKader);

    if (isKader) {
      final isMobile = MediaQuery.sizeOf(context).width < 600;

      return KaderWebScaffold(
        activeIndex: 6,
        breadcrumb: 'Beranda / Profil',
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider),
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: _buildProfileContent(
                  context,
                  isKader: true,
                  email: email,
                  palette: palette,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profil Saya',
            style: AppText.title.copyWith(color: AppColors.primaryNavy),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            LogoutButton(onPressed: _logout),
            const SizedBox(width: AppSpace.sm),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.divider),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 4,
          onTap: _onParentTabSelected,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.md,
            AppSpace.page,
            AppSpace.xxl,
          ),
          child: _buildProfileContent(
            context,
            isKader: false,
            email: email,
            palette: palette,
          ),
        ),
      ),
    );
  }
}