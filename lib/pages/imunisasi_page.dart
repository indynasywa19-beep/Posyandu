import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anak.dart';
import '../models/imunisasi.dart';
import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/child_picker.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';

class ImunisasiPage extends StatefulWidget {
  final bool openFormOnStart;

  const ImunisasiPage({super.key, this.openFormOnStart = false});

  @override
  State<ImunisasiPage> createState() => _ImunisasiPageState();
}

class _ImunisasiPageState extends State<ImunisasiPage> {
  List<Anak> dataAnak = [];
  List<Imunisasi> dataImunisasi = [];

  bool isLoading = true;
  bool _loadFailed = false;
  bool _autoFormShown = false;
  String _searchQuery = '';

  static const _belumAdaAnak =
      'Belum ada data anak. Tambahkan anak lebih dulu di menu Anak.';

  @override
  void initState() {
    super.initState();

    loadData().then((_) {
      if (!widget.openFormOnStart || _autoFormShown || !mounted) return;

      _autoFormShown = true;

      if (dataAnak.isNotEmpty) {
        tampilkanForm();
      } else {
        _showSnack(_belumAdaAnak);
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      _loadFailed = false;
    });

    try {
      final supabase = Supabase.instance.client;

      final dataAnakRows = await supabase.from('anak').select().order('nama');

      final dataImunisasiRows = await supabase
          .from('imunisasi')
          .select()
          .order('tanggal', ascending: false);

      final anakList = dataAnakRows.map((item) => Anak.fromMap(item)).toList();

      final imunisasiList = dataImunisasiRows
          .map((item) => Imunisasi.fromMap(item))
          .toList();

      if (!mounted) return;

      setState(() {
        dataAnak = anakList;
        dataImunisasi = imunisasiList;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadFailed = true);

      if (dataImunisasi.isNotEmpty) {
        _showSnack(
          friendlyError(
            e,
            fallback:
                'Data belum bisa diperbarui. Tarik layar ke bawah untuk mencoba lagi.',
          ),
        );
      } else {
        logError(e, 'muat imunisasi');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Anak? getChild(Object anakId) {
    try {
      return dataAnak.firstWhere((item) => item.id == anakId);
    } catch (_) {
      return null;
    }
  }

  String namaAnak(Object anakId) {
    final anak = getChild(anakId);

    return anak != null ? anak.nama : 'Anak tidak ditemukan';
  }

  String _tanggalTampil(String iso) {
    final date = DateTime.tryParse(iso);
    return date == null ? iso : tanggalLengkap(date);
  }

  Future<void> tampilkanForm({Imunisasi? imunisasi}) async {
    if (dataAnak.isEmpty) {
      _showSnack(_belumAdaAnak);
      return;
    }

    final message = await showDialog<String>(
      context: context,
      builder: (_) => Theme(
        data: AppTheme.kader,
        child: Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _ImunisasiFormSheet(
                children: dataAnak,
                imunisasi: imunisasi,
              ),
            ),
          ),
        ),
      ),
    );

    if (!mounted || message == null) return;

    _showSnack(message);
    await loadData();
  }

  Future<void> hapusData(Imunisasi imunisasi) async {
    final nama = namaAnak(imunisasi.anakId);

    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus catatan imunisasi?',
      message:
          'Imunisasi ${imunisasi.namaVaksin} untuk $nama tanggal ${_tanggalTampil(imunisasi.tanggal)} akan dihapus dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await Supabase.instance.client
          .from('imunisasi')
          .delete()
          .eq('id', imunisasi.id!);

      if (!mounted) return;

      _showSnack('Imunisasi ${imunisasi.namaVaksin} untuk $nama dihapus.');
      await loadData();
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        friendlyError(
          error,
          fallback: 'Catatan belum bisa dihapus. Coba lagi.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = dataImunisasi.where((item) {
      if (_searchQuery.isEmpty) return true;

      final childName = namaAnak(item.anakId).toLowerCase();
      final vaccine = item.namaVaksin.toLowerCase();
      final note = item.keterangan.toLowerCase();
      final q = _searchQuery.toLowerCase();

      return childName.contains(q) || vaccine.contains(q) || note.contains(q);
    }).toList();

    final total = dataImunisasi.length;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return KaderWebScaffold(
      activeIndex: 3,
      breadcrumb: 'Beranda / Input Imunisasi',
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 16 : 24,
          isMobile ? 16 : 24,
          8,
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile) ...[
                AppSearchField(
                  hint: 'Cari nama anak atau jenis vaksin',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => tampilkanForm(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Catat imunisasi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        hint: 'Cari nama anak atau jenis vaksin',
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => tampilkanForm(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Catat imunisasi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(140, 48),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              if (total > 0) ...[
                KaderInfoPill(
                  icon: Icons.vaccines_outlined,
                  message: _searchQuery.isEmpty
                      ? '$total catatan imunisasi'
                      : '${filteredList.length} dari $total catatan',
                ),
                const SizedBox(height: 16),
              ],

              _buildBody(filteredList),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Imunisasi> filtered) {
    if (isLoading && dataImunisasi.isEmpty && !_loadFailed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingState(message: 'Memuat catatan imunisasi'),
      );
    }

    if (_loadFailed && dataImunisasi.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorState(onRetry: loadData),
      );
    }

    if (dataImunisasi.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.vaccines_outlined,
          title: 'Belum ada catatan imunisasi',
          message: 'Catat vaksin dan vitamin yang sudah diberikan kepada anak.',
          actionLabel: 'Catat imunisasi',
          onAction: () => tampilkanForm(),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Tidak ada hasil',
          message: 'Tidak ada catatan yang cocok dengan "$_searchQuery".',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, index) {
        final item = filtered[index];

        return _RecordCard(
          vaccine: item.namaVaksin,
          childName: namaAnak(item.anakId),
          dateText: _tanggalTampil(item.tanggal),
          note: item.keterangan,
          onEdit: () => tampilkanForm(imunisasi: item),
          onDelete: () => hapusData(item),
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  final String vaccine;
  final String childName;
  final String dateText;
  final String note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.vaccine,
    required this.childName,
    required this.dateText,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.vaccines_rounded,
                  size: 24,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vaccine, style: AppText.subtitle),
                    Text(dateText, style: AppText.caption),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ubah imunisasi $vaccine untuk $childName',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Hapus imunisasi $vaccine untuk $childName',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppStatus.danger.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.md),
            child: Row(
              children: [
                InitialsAvatar(name: childName, size: 28),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(childName, style: AppText.label)),
              ],
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(note, style: AppText.body)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImunisasiFormSheet extends StatefulWidget {
  final List<Anak> children;
  final Imunisasi? imunisasi;

  const _ImunisasiFormSheet({required this.children, required this.imunisasi});

  @override
  State<_ImunisasiFormSheet> createState() => _ImunisasiFormSheetState();
}

class _ImunisasiFormSheetState extends State<_ImunisasiFormSheet> {
  static const _vaccineChips = [
    'HB-0',
    'BCG',
    'Polio',
    'DPT-HB-Hib',
    'Campak',
    'Vitamin A',
    'PCV',
    'Rotavirus',
  ];

  late final TextEditingController _customCtrl;
  late final TextEditingController _noteCtrl;

  Object? _selectedAnakId;
  late DateTime _selectedDate;
  String _selectedChip = '';

  bool _isSaving = false;
  String? _childError;
  String? _vaccineError;
  String? _errorMessage;

  bool get _isEdit => widget.imunisasi != null;

  @override
  void initState() {
    super.initState();

    final i = widget.imunisasi;

    if (i != null) {
      _selectedAnakId = i.anakId;
    } else if (widget.children.length == 1) {
      _selectedAnakId = widget.children.first.id;
    }

    _selectedDate = (i != null && i.tanggal.isNotEmpty)
        ? (DateTime.tryParse(i.tanggal) ?? DateTime.now())
        : DateTime.now();

    var custom = '';
    if (i != null && i.namaVaksin.isNotEmpty) {
      if (_vaccineChips.contains(i.namaVaksin)) {
        _selectedChip = i.namaVaksin;
      } else {
        custom = i.namaVaksin;
      }
    }

    _customCtrl = TextEditingController(text: custom);
    _noteCtrl = TextEditingController(text: i?.keterangan ?? '');
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Anak? get _child {
    if (_selectedAnakId == null) return null;
    for (final a in widget.children) {
      if (a.id == _selectedAnakId) return a;
    }
    return null;
  }

  bool get _dateIsFuture => DateUtils.dateOnly(
    _selectedDate,
  ).isAfter(DateUtils.dateOnly(DateTime.now()));

  Future<void> _pickChild() async {
    final id = await showChildPicker(
      context,
      children: widget.children
          .map((a) => {'id': a.id, 'nama': a.nama, 'nik': a.nik})
          .toList(),
      selectedId: _selectedAnakId?.toString(),
    );

    if (id == null || !mounted) return;

    for (final a in widget.children) {
      if (a.id.toString() == id) {
        setState(() {
          _selectedAnakId = a.id;
          _childError = null;
        });
        break;
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final vaccineName = _customCtrl.text.trim().isNotEmpty
        ? _customCtrl.text.trim()
        : _selectedChip;

    final child = _child;

    setState(() {
      _errorMessage = null;
      _childError = child == null ? 'Pilih anak terlebih dahulu.' : null;
      _vaccineError = vaccineName.isEmpty
          ? 'Pilih atau ketik jenis vaksin.'
          : null;
    });

    if (child == null || vaccineName.isEmpty) return;

    setState(() => _isSaving = true);

    final formattedDate =
        '${_selectedDate.year.toString().padLeft(4, '0')}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';

    final data = Imunisasi(
      id: widget.imunisasi?.id,
      anakId: _selectedAnakId!,
      namaVaksin: vaccineName,
      tanggal: formattedDate,
      keterangan: _noteCtrl.text.trim(),
    );

    try {
      final supabase = Supabase.instance.client;

      if (widget.imunisasi == null) {
        await supabase.from('imunisasi').insert(data.toMap());
      } else {
        await supabase
            .from('imunisasi')
            .update(data.toMap())
            .eq('id', widget.imunisasi!.id!);
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        _isEdit
            ? 'Perubahan imunisasi $vaccineName untuk ${child.nama} disimpan.'
            : 'Imunisasi $vaccineName untuk ${child.nama} disimpan.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = friendlyError(
          error,
          fallback:
              'Imunisasi belum tersimpan. Periksa koneksi internet, lalu coba lagi.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height;
    final child = _child;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                0,
                AppSpace.sm,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            _isEdit ? 'Ubah imunisasi' : 'Catat imunisasi',
                            style: AppText.title,
                          ),
                        ),
                        Text('Vaksin dan vitamin anak.', style: AppText.caption),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.sm,
                  AppSpace.page,
                  AppSpace.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Anak', style: AppText.label),
                    const SizedBox(height: 6),
                    KaderChildSelectorTile(
                      childName: child?.nama ?? '',
                      placeholder: child == null,
                      subtitle: child == null
                          ? null
                          : 'NIK: ${child.nik.isNotEmpty ? child.nik : '-'}',
                      onSelectChild: _pickChild,
                    ),
                    if (_childError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _childError!,
                        style: AppText.caption.copyWith(
                          color: AppStatus.danger.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.lg),

                    Text('Jenis imunisasi', style: AppText.label),
                    const SizedBox(height: AppSpace.sm),
                    ChoiceChipGroup(
                      options: _vaccineChips,
                      selected: _selectedChip,
                      onChanged: (value) {
                        setState(() {
                          _selectedChip = value;
                          if (value.isNotEmpty) _customCtrl.clear();
                          _vaccineError = null;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpace.md),
                    AppTextField(
                      label: 'Jenis lain',
                      controller: _customCtrl,
                      hint: 'Ketik jika tidak ada di pilihan di atas',
                      prefixIcon: Icons.vaccines_outlined,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            _selectedChip = '';
                            _vaccineError = null;
                          });
                        }
                      },
                    ),
                    if (_vaccineError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _vaccineError!,
                        style: AppText.caption.copyWith(
                          color: AppStatus.danger.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.lg),

                    Text('Tanggal pemberian', style: AppText.label),
                    const SizedBox(height: 6),
                    AppPickerTile(
                      icon: Icons.calendar_today_outlined,
                      value: tanggalLengkap(_selectedDate),
                      semanticLabel:
                          'Tanggal pemberian ${tanggalLengkap(_selectedDate)}. Ubah tanggal',
                      onTap: _pickDate,
                    ),
                    if (_dateIsFuture) ...[
                      const SizedBox(height: AppSpace.sm),
                      const InlineMessage(
                        status: AppStatus.warning,
                        message:
                            'Tanggal ini belum terjadi. Pastikan vaksin memang diberikan pada tanggal tersebut.',
                      ),
                    ],
                    const SizedBox(height: AppSpace.lg),

                    AppTextField(
                      label: 'Catatan (opsional)',
                      controller: _noteCtrl,
                      hint: 'Reaksi, dosis, dll.',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.lg,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null) ...[
                      InlineMessage(message: _errorMessage!),
                      const SizedBox(height: AppSpace.md),
                    ],
                    AppButton(
                      label: _isEdit ? 'Simpan perubahan' : 'Simpan imunisasi',
                      onPressed: _save,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}