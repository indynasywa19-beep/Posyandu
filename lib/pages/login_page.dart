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
    final now = DateTime.now();
    final footerText = '© [${now.year}] [SI-POSYANDU] · Kebijakan Privasi · v1.0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        if (isWide) {
          // ===================================================================
          // TAMPILAN WEB / LAYAR LEBAR - 2 Kolom (Umum)
          // ===================================================================
          return Scaffold(
            backgroundColor: Colors.white,
            body: Row(
              children: [
                // Kolom Kiri: Biru Navy Solid Polos
                Expanded(
                  flex: 5,
                  child: Container(
                    color: AppColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 56,
                      vertical: 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SiPosyanduBrand(
                          textColor: Colors.white,
                          govColor: Colors.white70,
                          iconSize: 40,
                        ),
                        const Spacer(),
                        Text(
                          'Sistem Informasi Posyandu',
                          style: AppText.headline.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Platform digital terpadu untuk layanan kesehatan Posyandu: pencatatan gizi, imunisasi, jadwal kegiatan, serta pemantauan tumbuh kembang anak.',
                          style: AppText.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Data kesehatan anak dilindungi dan hanya dapat diakses oleh pihak yang berwenang.',
                                style: AppText.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Kolom Kanan: Latar Putih Bersih
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 36,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _autoValidate
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Masuk ke akun',
                                  style: AppText.headline.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: AppSpace.xl),

                                AppTextField(
                                  label: 'Email',
                                  controller: _emailController,
                                  hint: 'nama@email.com',
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
                                  label: 'Password',
                                  controller: _passwordController,
                                  hint: 'Masukkan password',
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _login(),
                                  validator: (v) =>
                                      validateRequired(v, 'Password'),
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

                                const SizedBox(height: AppSpace.lg),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Belum punya akun? ',
                                      style: AppText.body.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          'Daftar',
                                          style: AppText.body.copyWith(
                                            color: AppColors.logoGreen,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.xxl),

                                Text(
                                  footerText,
                                  textAlign: TextAlign.center,
                                  style: AppText.caption.copyWith(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // =====================================================================
        // TAMPILAN MOBILE / LAYAR KECIL
        // =====================================================================
        return Scaffold(
          backgroundColor: AppColors.navy,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Atas: Header Biru Navy Solid Polos dengan Logo
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const SiPosyanduLogoIcon(size: 48),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SI-POSYANDU',
                        style: AppText.headline.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sistem Informasi Posyandu',
                        style: AppText.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PEMERINTAH [KABUPATEN/KOTA] · DINAS KESEHATAN',
                        style: AppText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bawah: Kartu Putih Melengkung Berisi Form
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autoValidate
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Masuk ke akun',
                                style: AppText.title.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: AppSpace.lg),

                              AppTextField(
                                label: 'Email',
                                controller: _emailController,
                                hint: 'nama@email.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                validator: validateEmail,
                              ),
                              const SizedBox(height: AppSpace.md),

                              AppTextField(
                                label: 'Password',
                                controller: _passwordController,
                                hint: 'Masukkan password',
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _login(),
                                validator: (v) =>
                                    validateRequired(v, 'Password'),
                              ),

                              if (_errorMessage != null) ...[
                                const SizedBox(height: AppSpace.md),
                                AuthMessage(message: _errorMessage!),
                              ],

                              const SizedBox(height: AppSpace.lg),
                              AppButton(
                                label: 'Masuk',
                                onPressed: _login,
                                isLoading: _isLoading,
                              ),

                              const SizedBox(height: AppSpace.md),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Belum punya akun? ',
                                    style: AppText.body.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        'Daftar',
                                        style: AppText.body.copyWith(
                                          color: AppColors.logoGreen,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpace.md),
                              // Kotak catatan perlindungan data
                              Container(
                                padding: const EdgeInsets.all(AppSpace.md),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 16,
                                      color: AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Data kesehatan anak dilindungi dan hanya dapat diakses oleh pihak yang berwenang.',
                                        style: AppText.caption.copyWith(
                                          color: AppColors.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpace.lg),
                              Text(
                                footerText,
                                textAlign: TextAlign.center,
                                style: AppText.caption.copyWith(
                                  color: AppColors.mutedText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}