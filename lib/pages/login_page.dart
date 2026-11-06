import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_ortu_page.dart';
import 'home_kader_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================
  // LOGIN SUPABASE
  // =========================
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = Supabase.instance.client.auth;

      final AuthResponse response = await auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        // Akun Kader
        if (response.user!.email?.toLowerCase() == 'kader@gmail.com') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeKaderPage()),
          );
        }
        // Akun Orang Tua
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeOrtuPage()),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal masuk. Periksa kembali email dan password Anda.\n$error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================
  // INPUT
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lavenderLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  // =========================
                  // BRAND
                  // =========================
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: lavender.withOpacity(0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: lavender.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: lavenderLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.health_and_safety_rounded,
                          size: 38,
                          color: primaryBlue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'SI-POSYANDU',
                    style: GoogleFonts.nunito(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: navy,
                      letterSpacing: 0.6,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Sistem Informasi Posyandu',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =========================
                  // LOGIN CARD
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
                        Text(
                          'Selamat Datang',
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: navy,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Silakan masuk untuk mengakses layanan '
                          'SI-POSYANDU.',
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            height: 1.5,
                            color: secondaryText,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // =========================
                        // EMAIL
                        // =========================
                        Text(
                          'Email',
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),

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
                            hint: 'Masukkan email Anda',
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // =========================
                        // PASSWORD
                        // =========================
                        Text(
                          'Password',
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),

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
                            hint: 'Masukkan password Anda',
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

                        const SizedBox(height: 24),

                        // =========================
                        // MASUK
                        // =========================
                        SizedBox(
                          width: double.infinity,
                          height: 51,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : login,
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
                                    'MASUK',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 21),

                        // =========================
                        // REGISTER
                        // =========================
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'Belum memiliki akun? ',
                                style: GoogleFonts.nunito(
                                  fontSize: 13.5,
                                  color: secondaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Daftar sekarang',
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

                  const SizedBox(height: 20),

                  // =========================
                  // SECURITY
                  // =========================
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: primaryBlue,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Data Anda terlindungi dan digunakan '
                            'untuk layanan Posyandu.',
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
                  ),

                  const SizedBox(height: 12),

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
}
