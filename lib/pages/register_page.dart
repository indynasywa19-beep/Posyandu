import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../utils/validators.dart';
import '../widgets/app_components.dart';
import '../widgets/app_theme.dart';
import '../widgets/auth_shell.dart';
import '../widgets/design_tokens.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();

  bool _isLoading = false;
  bool _autoValidate = false;
  String? _errorMessage;

  String _selectedRole = 'Orang Tua';

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // REGISTER SUPABASE (logika dan data yang dikirim tidak berubah)
  // ===========================================================================
  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'nama': _namaController.text.trim(), 'role': _selectedRole},
      );

      if (!mounted) return;

      if (response.user == null) {
        setState(
          () => _errorMessage = 'Pendaftaran belum berhasil. Coba lagi.',
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pendaftaran berhasil. Cek email Anda untuk verifikasi akun.',
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyError(
          error,
          fallback:
              'Pendaftaran belum berhasil. Periksa isian Anda, lalu coba lagi.',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // FORM PENDAFTARAN (dipakai bersama oleh tampilan Web & Mobile)
  // ===========================================================================
  Widget _buildRegisterForm({required bool isWide, required String footerText}) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Buat akun',
              style: AppText.headline.copyWith(
                fontSize: isWide ? 26 : 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Isi data berikut untuk mulai menggunakan SI-POSYANDU.',
              style: AppText.body.copyWith(color: AppColors.secondaryText),
            ),
            SizedBox(height: isWide ? AppSpace.xl : AppSpace.lg),

            AppTextField(
              label: 'Nama lengkap',
              controller: _namaController,
              hint: 'Masukkan nama lengkap',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => validateRequired(v, 'Nama lengkap'),
            ),
            SizedBox(height: isWide ? AppSpace.lg : AppSpace.md),

            AppTextField(
              label: 'Email',
              controller: _emailController,
              hint: 'nama@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: validateEmail,
            ),
            SizedBox(height: isWide ? AppSpace.lg : AppSpace.md),

            AppTextField(
              label: 'Kata sandi',
              controller: _passwordController,
              helper: 'Minimal 6 karakter.',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                final required = validateRequired(v, 'Kata sandi');
                if (required != null) return required;
                if (v!.length < 6) return 'Kata sandi minimal 6 karakter.';
                return null;
              },
            ),
            SizedBox(height: isWide ? AppSpace.lg : AppSpace.md),

            AppTextField(
              label: 'Ulangi kata sandi',
              controller: _konfirmasiController,
              prefixIcon: Icons.lock_reset_outlined,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              validator: (v) {
                final required = validateRequired(v, 'Ulangi kata sandi');
                if (required != null) return required;
                if (v != _passwordController.text) {
                  return 'Kata sandi tidak sama dengan isian di atas.';
                }
                return null;
              },
            ),
            SizedBox(height: isWide ? AppSpace.xl : AppSpace.lg),

            Text('Daftar sebagai', style: AppText.label),
            const SizedBox(height: AppSpace.sm),
            _RoleOption(
              title: 'Orang Tua',
              subtitle: 'Pantau tumbuh kembang anak',
              icon: Icons.family_restroom_rounded,
              selected: _selectedRole == 'Orang Tua',
              onTap: () => setState(() => _selectedRole = 'Orang Tua'),
            ),
            const SizedBox(height: AppSpace.sm),
            _RoleOption(
              title: 'Kader',
              subtitle: 'Kelola layanan Posyandu',
              icon: Icons.medical_services_outlined,
              selected: _selectedRole == 'Kader',
              onTap: () => setState(() => _selectedRole = 'Kader'),
            ),

            if (_errorMessage != null) ...[
              SizedBox(height: isWide ? AppSpace.lg : AppSpace.md),
              AuthMessage(message: _errorMessage!),
            ],

            SizedBox(height: isWide ? AppSpace.xl : AppSpace.lg),
            AppButton(
              label: 'Daftar',
              onPressed: _register,
              isLoading: _isLoading,
            ),

            SizedBox(height: isWide ? AppSpace.lg : AppSpace.md),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Sudah punya akun? ',
                  style: AppText.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Text(
                      'Masuk',
                      style: AppText.body.copyWith(
                        color: AppColors.logoGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isWide ? AppSpace.xl : AppSpace.lg),
            Text(
              footerText,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: AppColors.mutedText,
                fontSize: isWide ? 12 : 11.5,
              ),
            ),
          ],
        ),
      ),
    );
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
          // TAMPILAN WEB / LAYAR LEBAR - 2 Kolom
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
                          'Bergabung dengan platform digital terpadu untuk layanan kesehatan Posyandu, pencatatan gizi, dan pemantauan tumbuh kembang anak.',
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

                // Kolom Kanan: Form Pendaftaran Putih Bersih
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 36,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _buildRegisterForm(
                          isWide: true,
                          footerText: footerText,
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
                    vertical: 22,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const SiPosyanduLogoIcon(size: 40),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'SI-POSYANDU',
                        style: AppText.headline.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sistem Informasi Posyandu',
                        style: AppText.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: _buildRegisterForm(
                        isWide: false,
                        footerText: footerText,
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

/// Pilihan peran. Terpilih ditandai garis tebal, latar tint, dan ikon radio,
/// jadi tidak bergantung pada warna saja.
class _RoleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      excludeSemantics: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: '$title. $subtitle',
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primaryContainer : AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlAll,
          side: BorderSide(
            color: selected ? scheme.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected ? scheme.primary : AppColors.secondaryText,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.label),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? scheme.primary : AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}