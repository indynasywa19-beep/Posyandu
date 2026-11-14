import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Dialog konfirmasi dua pilihan. Mengembalikan true bila pengguna memilih
/// aksi utama, false bila membatalkan atau menutup dialog.
///
/// Pakai [destructive] untuk aksi yang tidak bisa dibatalkan (keluar akun,
/// hapus data). Sebut nama data yang terpengaruh di [message].
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: AppStatus.danger.foreground,
                )
              : null,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
