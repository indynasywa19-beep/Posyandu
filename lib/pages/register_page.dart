import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final konfirmasiPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedRole = 'Orang Tua';

  // =========================
  // COLOR PALETTE
  // =========================
  static const Color primaryBlue = Color(0xFF1261A0);
  static const Color lavender = Color(0xFFA99BCF);
  static const Color lavenderLight = Color(0xFFF4F1FA);
  static const Color navy = Color(0xFF123B5D);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    konfirmasiPasswordController.dispose();
    super.dispose();
  }

  // =========================
  // REGISTER
  // =========================
  Future<void> register() async {
    final nama = namaController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final konfirmasiPassword = konfirmasiPasswordController.text;

    if (nama.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        konfirmasiPassword.isEmpty) {
      _showMessage('Semua data wajib diisi.', Colors.red);
      return;
    }

    if (password.length < 6) {
      _showMessage('Password minimal 6 karakter.', Colors.red);
      return;
    }

    if (password != konfirmasiPassword) {
      _showMessage('Konfirmasi password tidak sesuai.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nama': nama, 'role': _selectedRole},
      );

      if (!mounted) return;

      if (response.user != null) {
        _showMessage(
          'Pendaftaran berhasil. Silakan cek email Anda untuk verifikasi akun.',
          Colors.green,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage('Pendaftaran gagal.\n$error', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // =========================
  // INPUT DECORATION
  // =========================
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(
        fontSize: 13.5,
        color: const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(icon, color: primaryBlue, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }

  // =========================
  // LABEL
  // =========================
  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lavenderLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  // =========================
                  // BACK BUTTON
                  // =========================
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, color: navy),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // =========================
                  // BRAND
                  // =========================
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: lavender.withOpacity(0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: lavender.withOpacity(0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: lavenderLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.health_and_safety_rounded,
                          size: 34,
                          color: primaryBlue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'SI-POSYANDU',
                    style: GoogleFonts.nunito(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: navy,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Sistem Informasi Posyandu',
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =========================
                  // REGISTER CARD
                  // =========================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7E2F0)),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withOpacity(0.07),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // =========================
                        // HEADER
                        // =========================
                        Text(
                          'Buat Akun',
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: navy,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Daftarkan diri Anda untuk menggunakan '
                          'layanan SI-POSYANDU.',
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            height: 1.5,
                            color: secondaryText,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // NAMA
                        // =========================
                        _label('Nama Lengkap'),

                        const SizedBox(height: 8),

                        TextField(
                          controller: namaController,
                          textCapitalization: TextCapitalization.words,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: navy,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _inputDecoration(
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outline_rounded,
                          ),
                        ),

                        const SizedBox(height: 17),

                        // =========================
                        // EMAIL
                        // =========================
                        _label('Email'),

                        const SizedBox(height: 8),

                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: navy,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _inputDecoration(
                            hint: 'Masukkan email',
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 17),

                        // =========================
                        // PASSWORD
                        // =========================
                        _label('Password'),

                        const SizedBox(height: 8),

                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: navy,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _inputDecoration(
                            hint: 'Minimal 6 karakter',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: secondaryText,
                                size: 21,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 17),

                        // =========================
                        // KONFIRMASI PASSWORD
                        // =========================
                        _label('Konfirmasi Password'),

                        const SizedBox(height: 8),

                        TextField(
                          controller: konfirmasiPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: navy,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _inputDecoration(
                            hint: 'Masukkan kembali password',
                            icon: Icons.lock_reset_outlined,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: secondaryText,
                                size: 21,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =========================
                        // ROLE
                        // =========================
                        _label('Daftar Sebagai'),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _roleCard(
                                title: 'Orang Tua',
                                subtitle: 'Pantau tumbuh kembang anak',
                                icon: Icons.family_restroom_rounded,
                                value: 'Orang Tua',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _roleCard(
                                title: 'Kader',
                                subtitle: 'Kelola layanan Posyandu',
                                icon: Icons.medical_services_outlined,
                                value: 'Kader',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // REGISTER BUTTON
                        // =========================
                        SizedBox(
                          width: double.infinity,
                          height: 51,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF94A3B8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'DAFTAR AKUN',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =========================
                        // LOGIN LINK
                        // =========================
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'Sudah memiliki akun? ',
                                style: GoogleFonts.nunito(
                                  fontSize: 13.5,
                                  color: secondaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Masuk sekarang',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: lavender,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =========================
                  // SECURITY
                  // =========================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Data Anda digunakan untuk kebutuhan '
                          'layanan Posyandu.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            color: secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '© 2026 SI-POSYANDU',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
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

  // =========================
  // ROLE CARD
  // =========================
  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final bool selected = _selectedRole == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? lavenderLight : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? lavender : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: selected ? primaryBlue : secondaryText,
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 19,
                    color: lavender,
                  ),
              ],
            ),

            const SizedBox(height: 9),

            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                height: 1.3,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
