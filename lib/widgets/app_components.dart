import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'design_tokens.dart';
import '../utils/app_copy.dart';

// =============================================================================
// Komponen reusable SI-Posyandu. Warna peran diambil dari Theme.of(context),
// jadi komponen yang sama otomatis berwarna Orang Tua atau Kader sesuai tema
// yang membungkusnya. Lihat design.md.
// =============================================================================

enum AppButtonVariant { primary, secondary, text }

/// Tombol standar. Tinggi minimal 48 dp.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// true: selebar induknya. false: selebar isinya.
  final bool expand;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    // Saat memuat, tombol tetap tampil aktif (bukan gaya nonaktif abu-abu)
    // supaya spinner terlihat, tetapi ketukan diabaikan.
    final VoidCallback? onTap = isLoading ? () {} : onPressed;
    final minSize = Size(expand ? double.infinity : 64, AppSize.touch);
    final style = ButtonStyle(minimumSize: WidgetStatePropertyAll(minSize));

    final Widget child = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: variant == AppButtonVariant.primary
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              const Text('Memproses'),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpace.sm),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(onPressed: onTap, style: style, child: child);
      case AppButtonVariant.secondary:
        return OutlinedButton(onPressed: onTap, style: style, child: child);
      case AppButtonVariant.text:
        return TextButton(onPressed: onTap, style: style, child: child);
    }
  }
}

/// Kolom isian dengan label di atas. Label selalu terlihat, tidak hilang
/// saat mengetik.
class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final bool enabled;
  final int maxLines;
  final IconData? prefixIcon;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLength;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.isPassword = false,
    this.enabled = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixText,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.maxLength,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(widget.label, style: AppText.label)),
        const SizedBox(height: 6),
        Semantics(
          label: widget.label,
          textField: true,
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            textCapitalization: widget.textCapitalization,
            maxLength: widget.maxLength,
            obscureText: widget.isPassword && _obscure,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            style: AppText.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helper,
              helperMaxLines: 2,
              errorMaxLines: 3,
              suffixText: widget.suffixText,
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(widget.prefixIcon, color: AppColors.secondaryText),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      tooltip: _obscure
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.secondaryText,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu datar: putih, garis tipis, tanpa bayangan. Pakai hanya bila isinya
/// memang satu kelompok yang berdiri sendiri.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Label status berupa ikon + teks + warna.
class StatusChip extends StatelessWidget {
  final String label;
  final AppStatus status;
  final bool showIcon;

  const StatusChip({
    super.key,
    required this.label,
    this.status = AppStatus.neutral,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: 16, color: status.foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: status.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul bagian dengan tautan aksi opsional di kanan.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppText.title),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppText.caption),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Keadaan kosong: jelaskan apa yang kosong dan apa langkah berikutnya.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: scheme.primary),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(title, style: AppText.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppText.body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.lg),
              AppButton(label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Keadaan gagal memuat. Selalu ada tombol "Coba lagi".
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Data belum bisa dimuat',
    this.message = 'Periksa koneksi internet Anda, lalu coba lagi.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppStatus.danger.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppStatus.danger.icon,
                size: 30,
                color: AppStatus.danger.foreground,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(title, style: AppText.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppText.body, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpace.lg),
              AppButton(
                label: 'Coba lagi',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                expand: false,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Indikator memuat di tengah area.
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: message ?? 'Memuat data',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpace.md),
              Text(message!, style: AppText.body),
            ],
          ],
        ),
      ),
    );
  }
}

/// Avatar berisi inisial nama. Warna dipilih dari nama sehingga selalu sama
/// untuk anak yang sama. Menggantikan wajah kartun [ChildAvatar].
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool selected;

  /// Titik status kecil di sudut. Selalu sertakan teks status di dekatnya.
  final Color? statusColor;
  final String? semanticLabel;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.selected = false,
    this.statusColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final seed = name.trim().codeUnits.fold<int>(0, (a, b) => a + b);
    final pair = AppColors.avatarPairs[seed % AppColors.avatarPairs.length];
    final ring = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (selected)
                Container(
                  width: size + 6,
                  height: size + 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2),
                  ),
                ),
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: pair.$1, shape: BoxShape.circle),
                child: Text(
                  initialsOf(name),
                  textScaler: TextScaler.noScaling,
                  style: AppText.label.copyWith(
                    color: pair.$2,
                    fontSize: size * 0.38,
                  ),
                ),
              ),
              if (statusColor != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile menu layanan: ikon di atas, judul, keterangan singkat.
/// Satu gaya warna (tint peran), tanpa warna acak per tile.
class ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ServiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpace.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadius.controlAll,
              ),
              child: Icon(icon, size: 24, color: scheme.primary),
            ),
            const SizedBox(height: AppSpace.md),
            Text(title, style: AppText.label.copyWith(fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

/// Susunan dua kolom untuk [ServiceTile]. Tinggi tiap baris mengikuti isi
/// terpanjang, jadi aman saat font sistem diperbesar (tidak memakai
/// rasio tetap seperti GridView.childAspectRatio).
class ServiceGrid extends StatelessWidget {
  final List<Widget> children;

  const ServiceGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final second = i + 1 < children.length ? children[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: AppSpace.md),
              Expanded(child: second ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: AppSpace.md));
      }
    }
    return Column(children: rows);
  }
}

/// Pesan di dalam form atau lembar. Tidak hilang sendiri seperti snackbar
/// dan dibacakan pembaca layar saat muncul. Pakai ini (bukan snackbar) di
/// dalam bottom sheet, karena snackbar tampil di belakang lembar.
class InlineMessage extends StatelessWidget {
  final String message;
  final AppStatus status;

  const InlineMessage({
    super.key,
    required this.message,
    this.status = AppStatus.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: AppRadius.controlAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(status.icon, size: 20, color: status.foreground),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                message,
                style: AppText.body.copyWith(
                  color: status.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kolom cari langsung di halaman (menyaring saat mengetik), menggantikan
/// dialog cari. Ada tombol hapus bila terisi.
class AppSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;

  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: widget.hint,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        textInputAction: TextInputAction.search,
        style: AppText.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.secondaryText,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Baris yang membuka pemilih (tanggal, anak, dan sejenisnya).
/// Seluruh baris bisa diketuk dan berlabel untuk pembaca layar.
class AppPickerTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String actionLabel;
  final VoidCallback onTap;
  final String? semanticLabel;

  /// true bila [value] hanya teks petunjuk (belum ada pilihan): tampil lebih
  /// pudar dan tombolnya berbunyi "Pilih".
  final bool isPlaceholder;

  const AppPickerTile({
    super.key,
    required this.icon,
    required this.value,
    required this.onTap,
    this.actionLabel = 'Ubah',
    this.semanticLabel,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: semanticLabel ?? '$value. $actionLabel',
      onTap: onTap,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlAll,
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: scheme.primary),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      value,
                      style: isPlaceholder
                          ? AppText.bodyLarge.copyWith(
                              color: AppColors.secondaryText,
                            )
                          : AppText.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    isPlaceholder ? 'Pilih' : actionLabel,
                    style: AppText.caption.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
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

/// Isian ukuran (berat, tinggi). Angka diketik langsung, dengan tombol - dan +
/// untuk koreksi kecil.
///
/// Sengaja dimulai kosong untuk catatan baru: nilai bawaan yang tampak benar
/// (misalnya 10 kg) bisa tersimpan tanpa pernah diukur.
class MeasurementField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final double step;
  final double min;
  final double max;
  final String? helper;

  const MeasurementField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    required this.step,
    required this.min,
    required this.max,
    this.helper,
  });

  static double? parse(String? text) {
    if (text == null) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  String? _validate(String? text) {
    if (text == null || text.trim().isEmpty) return '$label wajib diisi.';
    final value = parse(text);
    if (value == null) return 'Isi dengan angka, contoh: 12.4';
    if (value < min || value > max) {
      return '$label harus antara ${_fmt(min)} dan ${_fmt(max)} $unit.';
    }
    return null;
  }

  void _nudge(double delta) {
    final current = parse(controller.text);
    if (current == null) return;
    final next = (current + delta).clamp(min, max);
    controller.text = next.toStringAsFixed(1);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(label, style: AppText.label)),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasValue = parse(value.text) != null;
            return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconButton.filledTonal(
                tooltip: 'Kurangi ${label.toLowerCase()}',
                onPressed: hasValue ? () => _nudge(-step) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Semantics(
                textField: true,
                label: '$label dalam $unit',
                child: TextFormField(
                  controller: controller,
                  validator: _validate,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.next,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: AppText.title.copyWith(fontSize: 24),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    suffixText: unit,
                    suffixStyle: AppText.label.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    helperText: helper,
                    helperMaxLines: 2,
                    errorMaxLines: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconButton.filled(
                tooltip: 'Tambah ${label.toLowerCase()}',
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: hasValue ? () => _nudge(step) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
            );
          },
        ),
      ],
    );
  }
}

/// Pilihan tunggal berupa chip. Mengetuk chip yang sedang terpilih
/// membatalkan pilihan (mengembalikan ''). Terpilih ditandai warna, tanda
/// centang, dan label tebal.
class ChoiceChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const ChoiceChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.xs,
      children: options.map((option) {
        final isSelected = selected == option;

        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: scheme.onPrimary,
          selectedColor: scheme.primary,
          backgroundColor: scheme.primaryContainer,
          side: BorderSide.none,
          labelStyle: AppText.caption.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? scheme.onPrimary : scheme.primary,
          ),
          onSelected: (value) => onChanged(value ? option : ''),
        );
      }).toList(),
    );
  }
}
