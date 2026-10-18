import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_widgets.dart';
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final auth = Supabase.instance.client.auth;
    try {
      await auth.signOut();
      final AuthResponse response = await auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted && response.user != null) {
        if (response.user!.email?.toLowerCase() == 'kader@gmail.com') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeKaderPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeOrtuPage()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login tidak berhasil. Silakan coba kembali.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      Object? cleanupError;
      try {
        await auth.signOut();
      } catch (error) {
        cleanupError = error;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cleanupError == null
                  ? 'Gagal masuk: email atau password salah. ($error)'
                  : 'Gagal masuk dan sesi gagal dibersihkan: $cleanupError',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthLayout(
        headerHeight: 330,
        title: 'SI-POSYANDU',
        subtitle: 'Sistem Informasi Posyandu',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Masuk sebagai Kader atau Orang Tua',
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 20),
            AuthField(
              controller: emailController,
              hint: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            AuthField(
              controller: passwordController,
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Masuk',
              loading: _isLoading,
              onPressed: _isLoading ? null : login,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: Text.rich(
                  TextSpan(
                    text: 'Belum punya akun? ',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF475569),
                    ),
                    children: [
                      TextSpan(
                        text: 'Daftar sekarang',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: kAuthGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RoleDot(color: kAuthBlue, label: 'Kader'),
                  SizedBox(width: 18),
                  RoleDot(color: kAuthGreen, label: 'Orang Tua'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}