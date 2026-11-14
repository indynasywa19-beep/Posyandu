import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'design_tokens.dart';

/// Lembar pemilih anak. Mengembalikan `id` anak yang dipilih, atau null bila
/// ditutup tanpa memilih.
///
/// [children] adalah baris tabel `anak` (kunci `id`, `nama`, `nik`).
/// Kolom cari muncul bila anaknya lebih dari [searchThreshold].
Future<String?> showChildPicker(
  BuildContext context, {
  required List<Map<String, dynamic>> children,
  String? selectedId,
  int searchThreshold = 8,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _ChildPickerSheet(
      children: children,
      selectedId: selectedId,
      showSearch: children.length > searchThreshold,
    ),
  );
}

class _ChildPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> children;
  final String? selectedId;
  final bool showSearch;

  const _ChildPickerSheet({
    required this.children,
    required this.selectedId,
    required this.showSearch,
  });

  @override
  State<_ChildPickerSheet> createState() => _ChildPickerSheetState();
}

class _ChildPickerSheetState extends State<_ChildPickerSheet> {
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.children;
    return widget.children.where((c) {
      final nama = (c['nama'] ?? '').toString().toLowerCase();
      final nik = (c['nik'] ?? '').toString().toLowerCase();
      return nama.contains(q) || nik.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final items = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                0,
                AppSpace.page,
                AppSpace.md,
              ),
              child: Semantics(
                header: true,
                child: Text('Pilih anak', style: AppText.title),
              ),
            ),
            if (widget.showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  0,
                  AppSpace.page,
                  AppSpace.sm,
                ),
                child: AppSearchField(
                  hint: 'Cari nama atau NIK',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            Flexible(
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpace.xl),
                      child: Center(child: Text('Tidak ada anak yang cocok.')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: AppSpace.lg),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final id = item['id'].toString();
                        final nama = (item['nama'] ?? 'Tanpa nama').toString();
                        final nik = (item['nik'] ?? '-').toString();
                        final selected = id == widget.selectedId;

                        return Semantics(
                          button: true,
                          selected: selected,
                          excludeSemantics: true,
                          label: '$nama, NIK $nik',
                          onTap: () => Navigator.pop(context, id),
                          child: InkWell(
                            onTap: () => Navigator.pop(context, id),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppSize.touch + 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.page,
                                  vertical: AppSpace.sm,
                                ),
                                child: Row(
                                  children: [
                                    InitialsAvatar(name: nama, size: 40),
                                    const SizedBox(width: AppSpace.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(nama, style: AppText.subtitle),
                                          Text(
                                            'NIK: $nik',
                                            style: AppText.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: scheme.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
