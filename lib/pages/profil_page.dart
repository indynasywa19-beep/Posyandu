import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  User? get _user => Supabase.instance.client.auth.currentUser;

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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Nama lengkap tidak boleh kosong.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'display_name': name}),
      );

      _showMessage('Profil berhasil diperbarui.');
    } catch (error) {
      _showMessage('Gagal memperbarui profil: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      _showMessage('Gagal keluar dari akun: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Widget _buildKaderPage(BuildContext context, String email) {
    const kaderBlue = Color(0xFF1261A0);
    const kaderNavy = Color(0xFF123B5D);
    const kaderLavender = Color(0xFFA99BCF);
    const kaderLavenderSoft = Color(0xFFF4F1FA);
    const kaderBlueSoft = Color(0xFFEAF3FA);
    const kaderTextSecondary = Color(0xFF64748B);
    const kaderBorder = Color(0xFFE2E8F0);

    return Theme(
      data: AppTheme.kader.copyWith(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,

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

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: 3,
          onTabSelected: (index) {
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
          },
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: kaderNavy,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profil Saya',
                            style: GoogleFonts.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: kaderNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kelola informasi akun Anda',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kaderTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    KaderLogoutButton(onPressed: _logout),
                  ],
                ),

                const SizedBox(height: 20),

                // PROFILE CARD
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kaderBlue, kaderNavy],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _nameController.text.isEmpty
                            ? 'Kader Posyandu'
                            : _nameController.text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Kader Posyandu Aktif',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // TITLE
                Text(
                  'Informasi Akun',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kaderNavy,
                  ),
                ),

                const SizedBox(height: 14),

                // NAME FIELD
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kaderNavy,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    labelStyle: GoogleFonts.nunito(
                      fontSize: 13,
                      color: kaderTextSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: kaderBlue,
                    ),
                    filled: true,
                    fillColor: kaderBlueSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: kaderBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 14),

                // EMAIL
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kaderLavenderSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kaderBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: kaderBlue),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: GoogleFonts.nunito(
                                color: kaderTextSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              email,
                              style: GoogleFonts.nunito(
                                color: kaderNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ROLE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kaderBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: kaderLavenderSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: kaderLavender,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role Akun',
                              style: GoogleFonts.nunito(
                                color: kaderTextSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Kader Posyandu',
                              style: GoogleFonts.nunito(
                                color: kaderNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SAVE BUTTON
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: kaderBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Profil',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // INFO
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: kaderLavenderSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: kaderLavender,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Pastikan informasi profil yang digunakan sudah sesuai agar data akun tetap mudah dikenali.',
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: kaderNavy,
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
      ),
    );
  }

  Widget _buildOrtuPage(BuildContext context, String email) {
    final accentColor = AppColors.parent;

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: const Text('Profil Saya'),
          actions: [
            LogoutButton(onPressed: _logout),
            const SizedBox(width: 12),
          ],
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PROFILE
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _nameController.text.isEmpty
                          ? 'Profil SI-Posyandu'
                          : _nameController.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Orang Tua / Wali',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Informasi Akun',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 12),

              // NAME
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              // EMAIL
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: accentColor),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            email,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // SAVE
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(backgroundColor: accentColor),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Profil'),
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 4,
          onTap: (index) {
            final page = switch (index) {
              0 => const HomeOrtuPage(),
              1 => const DataAnakPage(),
              2 => const JadwalPage(),
              3 => const ArtikelPage(),
              _ => null,
            };

            if (page != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final email = user?.email ?? '-';

    final isKader = email.toLowerCase() == 'kader@gmail.com';

    if (isKader) {
      return _buildKaderPage(context, email);
    }

    return _buildOrtuPage(context, email);
  }
}
