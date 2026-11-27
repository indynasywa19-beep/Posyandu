import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'design_tokens.dart';

/// Kerangka halaman masuk dan daftar: merek di atas, isi di tengah,
/// tautan pindah halaman dan catatan data di bawah.
class AuthShell extends StatelessWidget {
  final Widget child;

  /// Biasanya [AuthSwitchPrompt].
  final Widget? footer;
  final bool showBack;

  const AuthShell({
    super.key,
    required this.child,
    this.footer,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.page,
              vertical: AppSpace.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Kembali',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),

                  // Merek SI-POSYANDU
                  const Center(
                    child: SiPosyanduBrand(
                      iconSize: 52,
                      isVertical: true,
                      showGovHeader: true,
                      showSubtitle: true,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  child,

                  if (footer != null) ...[
                    const SizedBox(height: AppSpace.md),
                    footer!,
                  ],
                  const SizedBox(height: AppSpace.md),
                  Text(
                    'Data kesehatan anak dilindungi dan hanya dapat diakses oleh pihak yang berwenang.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: AppColors.mutedText),
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

/// Pesan di dalam form masuk/daftar. Memakai [InlineMessage] yang sama
/// dengan halaman lain.
class AuthMessage extends StatelessWidget {
  final String message;
  final AppStatus status;

  const AuthMessage({
    super.key,
    required this.message,
    this.status = AppStatus.danger,
  });

  @override
  Widget build(BuildContext context) =>
      InlineMessage(message: message, status: status);
}

/// "Belum punya akun? Daftar". Tautan berupa tombol teks dengan area
/// sentuh 48 dp dan warna yang lolos kontras.
class AuthSwitchPrompt extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppText.body),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
