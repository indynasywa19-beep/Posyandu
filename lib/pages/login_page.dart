import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../utils/validators.dart';
import '../widgets/app_components.dart';
import '../widgets/app_theme.dart';
import '../widgets/auth_shell.dart';
import '../widgets/design_tokens.dart';
import 'home_kader_page.dart';
import 'home_ortu_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _autoValidate = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOGIN SUPABASE (logika tidak berubah)
  // ===========================================================================
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = response.user;
      if (user == null) {
        setState(() => _errorMessage = 'Masuk belum berhasil. Coba lagi.');
        return;
      }

      // Peran masih ditentukan dari email. Ditunda atas keputusan pemilik
      // proyek (masalah no. 17), sengaja tidak diubah di langkah desain ini.
      final Widget next = user.email?.toLowerCase() == 'kader@gmail.com'
          ? const HomeKaderPage()
          : const HomeOrtuPage();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyError(
          error,
          fallback:
              'Gagal masuk. Periksa email dan kata sandi Anda, lalu coba lagi.',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      footer: AuthSwitchPrompt(
        prompt: 'Belum punya akun?',
        actionLabel: 'Daftar',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          );
        },
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Masuk ke akun Anda', style: AppText.title),
                const SizedBox(height: 6),
                Text(
                  'Gunakan email dan kata sandi yang Anda daftarkan.',
                  style: AppText.body.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: AppSpace.xl),

                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'nama@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  validator: validateEmail,
                ),
                const SizedBox(height: AppSpace.lg),

                AppTextField(
                  label: 'Kata sandi',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _login(),
                  validator: (v) => validateRequired(v, 'Kata sandi'),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpace.lg),
                  AuthMessage(message: _errorMessage!),
                ],

                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'Masuk',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
