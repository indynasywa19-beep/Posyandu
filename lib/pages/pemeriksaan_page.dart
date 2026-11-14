import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/child_picker.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'data_anak_page.dart';
import 'home_kader_page.dart';
import 'jadwal_page.dart';
import 'profil_page.dart';

class Pemeriksaan {
  final String? id;
  final String anakId;
  final String tanggal;
  final double beratBadan;
  final double tinggiBadan;
  final String catatan;

  Pemeriksaan({
    this.id,
    required this.anakId,
    required this.tanggal,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.catatan,
  });

  factory Pemeriksaan.fromMap(Map<String, dynamic> map) {
    return Pemeriksaan(
      id: map['id']?.toString(),
      anakId: map['anak_id']?.toString() ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      beratBadan: double.tryParse(map['berat_badan']?.toString() ?? '0') ?? 0,
      tinggiBadan: double.tryParse(map['tinggi_badan']?.toString() ?? '0') ?? 0,
      catatan: map['catatan']?.toString() ?? '',
    );
  }
}

class PemeriksaanPage extends StatefulWidget {
  final bool openFormOnStart;

  const PemeriksaanPage({super.key, this.openFormOnStart = false});

  @override
  State<PemeriksaanPage> createState() => _PemeriksaanPageState();
}

class _PemeriksaanPageState extends State<PemeriksaanPage> {
  List<dynamic> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];

  bool _isLoading = true;
  bool _loadFailed = false;
  bool _autoFormShown = false;
  String _searchQuery = '';

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

  static const _belumAdaAnak =
      'Belum ada data anak. Tambahkan anak lebih dulu di menu Anak.';

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final supabase = Supabase.instance.client;

      final anakResponse = await supabase.from('anak').select().order('nama');

      final periksaResponse = await supabase
          .from('pemeriksaan')
          .select()
          .order('tanggal', ascending: false);

      if (!mounted) return;

      setState(() {
        dataAnak = anakResponse as List<dynamic>;

        dataPemeriksaan = (periksaResponse as List<dynamic>)
            .map((item) => Pemeriksaan.fromMap(item as Map<String, dynamic>))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loadFailed = true);

      // Bila belum ada data, layar menampilkan ErrorState dengan "Coba lagi".
      // Bila sudah ada data lama di layar, cukup beri tahu lewat snackbar.
      if (dataPemeriksaan.isNotEmpty) {
        _showSnack(
          friendlyError(
            error,
            fallback: 'Data belum bisa diperbarui. Tarik layar ke bawah untuk mencoba lagi.',
          ),
        );
      } else {
        logError(error, 'muat pemeriksaan');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic>? getChildData(String anakId) {
    try {
      return dataAnak.firstWhere(
            (item) => item['id'].toString() == anakId,
            orElse: () => null,
          )
          as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  String namaAnak(String anakId) {
    final child = getChildData(anakId);

    return child != null
        ? (child['nama'] ?? 'Tidak Diketahui')
        : 'Tidak Diketahui';
  }

  String _tanggalTampil(String iso) {
    final date = DateTime.tryParse(iso);
    return date == null ? iso : tanggalLengkap(date);
  }

  // ---------------------------------------------------------------------------
  // FORM TAMBAH / UBAH
  // ---------------------------------------------------------------------------
  Future<void> tampilkanForm({Pemeriksaan? pemeriksaan}) async {
    if (dataAnak.isEmpty) {
      _showSnack(_belumAdaAnak);
      return;
    }

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Theme(
        data: AppTheme.kader,
        child: _PemeriksaanFormSheet(
          children: dataAnak.whereType<Map<String, dynamic>>().toList(),
          pemeriksaan: pemeriksaan,
        ),
      ),
    );

    if (!mounted || message == null) return;

    _showSnack(message);
    await loadData();
  }

  // ---------------------------------------------------------------------------
  // HAPUS
  // ---------------------------------------------------------------------------
  Future<void> _hapus(Pemeriksaan pemeriksaan) async {
    final nama = namaAnak(pemeriksaan.anakId);

    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus catatan gizi?',
      message:
          'Catatan gizi $nama tanggal ${_tanggalTampil(pemeriksaan.tanggal)} akan dihapus dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await Supabase.instance.client
          .from('pemeriksaan')
          .delete()
          .eq('id', pemeriksaan.id!);

      if (!mounted) return;

      _showSnack('Catatan gizi $nama dihapus.');
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

  // ---------------------------------------------------------------------------
  // NAVIGASI
  // ---------------------------------------------------------------------------
  void _onNavigationTap(BuildContext context, int index) {
    // KaderBottomAppBar: 0=Beranda, 1=Anak, [FAB=CatatGizi], 2=Jadwal, 3=Profil
    final Widget? page = switch (index) {
      0 => const HomeKaderPage(),
      1 => const DataAnakPage(isKader: true),
      2 => const JadwalPage(isKader: true),
      3 => const ProfilPage(),
      _ => null,
    };

    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  Widget _buildBody(List<Pemeriksaan> filtered) {
    if (_isLoading && dataPemeriksaan.isEmpty && !_loadFailed) {
      return const LoadingState(message: 'Memuat catatan gizi');
    }

    if (_loadFailed && dataPemeriksaan.isEmpty) {
      return ErrorState(onRetry: loadData);
    }

    if (dataPemeriksaan.isEmpty) {
      return EmptyState(
        icon: Icons.monitor_weight_outlined,
        title: 'Belum ada catatan gizi',
        message:
            'Catat berat dan tinggi badan anak untuk mulai memantau pertumbuhannya.',
        actionLabel: 'Catat gizi',
        onAction: () => tampilkanForm(),
      );
    }

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Tidak ada hasil',
        message: 'Tidak ada catatan yang cocok dengan "$_searchQuery".',
      );
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.sm,
          AppSpace.page,
          AppSpace.xl,
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
        itemBuilder: (context, index) {
          final item = filtered[index];
          final nama = namaAnak(item.anakId);

          return _RecordCard(
            name: nama,
            dateText: _tanggalTampil(item.tanggal),
            weight: '${item.beratBadan} kg',
            height: '${item.tinggiBadan} cm',
            note: item.catatan,
            onEdit: () => tampilkanForm(pemeriksaan: item),
            onDelete: () => _hapus(item),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = dataPemeriksaan.where((p) {
      if (_searchQuery.isEmpty) return true;

      final name = namaAnak(p.anakId).toLowerCase();
      final note = p.catatan.toLowerCase();
      final q = _searchQuery.toLowerCase();

      return name.contains(q) || note.contains(q);
    }).toList();

    final total = dataPemeriksaan.length;

    return Theme(
      data: AppTheme.kader,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.page,
                  AppSpace.sm,
                ),
                child: KaderTopBar(
                  title: 'Catat Gizi',
                  subtitle: 'Timbang & ukur pertumbuhan anak',
                  onBack: () => Navigator.maybePop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                child: AppSearchField(
                  hint: 'Cari nama anak atau catatan',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              if (total > 0) ...[
                const SizedBox(height: AppSpace.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
                  ),
                  child: KaderInfoPill(
                    icon: Icons.history_rounded,
                    message: _searchQuery.isEmpty
                        ? '$total catatan pengukuran gizi'
                        : '${filteredList.length} dari $total catatan',
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              Expanded(child: _buildBody(filteredList)),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: KaderCenterFab(onPressed: () => tampilkanForm()),
        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: -1,
          onTabSelected: (index) => _onNavigationTap(context, index),
        ),
      ),
    );
  }
}

// =============================================================================
// KARTU RIWAYAT
// =============================================================================
class _RecordCard extends StatelessWidget {
  final String name;
  final String dateText;
  final String weight;
  final String height;
  final String note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.name,
    required this.dateText,
    required this.weight,
    required this.height,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
              InitialsAvatar(name: name, size: 44),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.subtitle),
                    Text(dateText, style: AppText.caption),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ubah catatan gizi $name',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Hapus catatan gizi $name',
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
                Expanded(
                  child: _Measure(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Berat',
                    value: weight,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _Measure(
                    icon: Icons.height_rounded,
                    label: 'Tinggi',
                    value: height,
                  ),
                ),
              ],
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
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

class _Measure extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Measure({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppStatus.neutral.background,
        borderRadius: AppRadius.controlAll,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppStatus.neutral.foreground),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.caption.copyWith(
                    color: AppStatus.neutral.foreground,
                  ),
                ),
                Text(value, style: AppText.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LEMBAR FORM
// =============================================================================
class _PemeriksaanFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> children;
  final Pemeriksaan? pemeriksaan;

  const _PemeriksaanFormSheet({
    required this.children,
    required this.pemeriksaan,
  });

  @override
  State<_PemeriksaanFormSheet> createState() => _PemeriksaanFormSheetState();
}

class _PemeriksaanFormSheetState extends State<_PemeriksaanFormSheet> {
  static const _noteChips = [
    'ASI eksklusif',
    'MP-ASI',
    'Nafsu makan baik',
    'Perlu PMT',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _noteCtrl;

  late String _selectedChildId;
  late DateTime _selectedDate;
  String _selectedChip = '';

  bool _isSaving = false;
  bool _autoValidate = false;
  String? _childError;
  String? _errorMessage;

  bool get _isEdit => widget.pemeriksaan != null;

  @override
  void initState() {
    super.initState();

    final p = widget.pemeriksaan;

    // Catatan baru: anak TIDAK dipilih otomatis (kecuali hanya ada satu),
    // supaya catatan tidak tersimpan ke anak yang salah tanpa disadari.
    if (p != null) {
      _selectedChildId = p.anakId;
    } else if (widget.children.length == 1) {
      _selectedChildId = widget.children.first['id'].toString();
    } else {
      _selectedChildId = '';
    }

    _selectedDate = (p != null && p.tanggal.isNotEmpty)
        ? (DateTime.tryParse(p.tanggal) ?? DateTime.now())
        : DateTime.now();

    // Catatan baru: berat dan tinggi dimulai KOSONG, bukan 10 kg / 75 cm.
    _weightCtrl = TextEditingController(
      text: (p != null && p.beratBadan > 0)
          ? p.beratBadan.toStringAsFixed(1)
          : '',
    );
    _heightCtrl = TextEditingController(
      text: (p != null && p.tinggiBadan > 0)
          ? p.tinggiBadan.toStringAsFixed(1)
          : '',
    );

    var customNote = '';
    if (p != null && p.catatan.isNotEmpty) {
      if (_noteChips.contains(p.catatan)) {
        _selectedChip = p.catatan;
      } else {
        customNote = p.catatan;
      }
    }
    _noteCtrl = TextEditingController(text: customNote);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _child {
    for (final c in widget.children) {
      if (c['id'].toString() == _selectedChildId) return c;
    }
    return null;
  }

  String get _childName => (_child?['nama'] ?? 'Tidak Diketahui').toString();

  Future<void> _pickChild() async {
    final id = await showChildPicker(
      context,
      children: widget.children,
      selectedId: _selectedChildId.isEmpty ? null : _selectedChildId,
    );

    if (id != null && mounted) {
      setState(() {
        _selectedChildId = id;
        _childError = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(2020);
    var initial = _selectedDate;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(now)) initial = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final formOk = _formKey.currentState!.validate();
    final childOk = _selectedChildId.isNotEmpty;

    setState(() {
      _childError = childOk ? null : 'Pilih anak terlebih dahulu.';
      if (!formOk || !childOk) _autoValidate = true;
    });

    if (!formOk || !childOk) return;

    setState(() => _isSaving = true);

    // Dibulatkan ke satu desimal, sama seperti sebelumnya.
    final weight = double.parse(
      MeasurementField.parse(_weightCtrl.text)!.toStringAsFixed(1),
    );
    final height = double.parse(
      MeasurementField.parse(_heightCtrl.text)!.toStringAsFixed(1),
    );

    final formattedDate =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final finalNote = _selectedChip.isNotEmpty
        ? _selectedChip
        : _noteCtrl.text.trim();

    final mapData = {
      'anak_id': _selectedChildId,
      'tanggal': formattedDate,
      'berat_badan': weight,
      'tinggi_badan': height,
      'catatan': finalNote,
    };

    try {
      final supabase = Supabase.instance.client;

      if (widget.pemeriksaan == null) {
        await supabase.from('pemeriksaan').insert(mapData);
      } else {
        await supabase
            .from('pemeriksaan')
            .update(mapData)
            .eq('id', widget.pemeriksaan!.id!);
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        _isEdit
            ? 'Perubahan catatan gizi $_childName disimpan.'
            : 'Catatan gizi $_childName disimpan.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = friendlyError(
          error,
          fallback:
              'Catatan gizi belum tersimpan. Periksa koneksi internet, lalu coba lagi.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            // Kepala
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
                            _isEdit ? 'Ubah catatan gizi' : 'Catat gizi',
                            style: AppText.title,
                          ),
                        ),
                        Text(
                          'Isi hasil timbang dan ukur anak.',
                          style: AppText.caption,
                        ),
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

            // Isi
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
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Anak', style: AppText.label),
                      const SizedBox(height: 6),
                      KaderChildSelectorTile(
                        childName: child == null ? '' : _childName,
                        placeholder: child == null,
                        subtitle: child == null
                            ? null
                            : 'NIK: ${child['nik'] ?? '-'}',
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

                      Text('Tanggal pemeriksaan', style: AppText.label),
                      const SizedBox(height: 6),
                      AppPickerTile(
                        icon: Icons.calendar_today_outlined,
                        value: tanggalLengkap(_selectedDate),
                        semanticLabel:
                            'Tanggal pemeriksaan ${tanggalLengkap(_selectedDate)}. Ubah tanggal',
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpace.lg),

                      MeasurementField(
                        label: 'Berat badan',
                        unit: 'kg',
                        controller: _weightCtrl,
                        step: 0.1,
                        min: 0.5,
                        max: 100,
                        helper: 'Ketik angka, contoh: 12.4',
                      ),
                      const SizedBox(height: AppSpace.lg),

                      MeasurementField(
                        label: 'Tinggi badan',
                        unit: 'cm',
                        controller: _heightCtrl,
                        step: 0.5,
                        min: 20,
                        max: 200,
                        helper: 'Ketik angka, contoh: 78.5',
                      ),
                      const SizedBox(height: AppSpace.lg),

                      Text('Catatan gizi (opsional)', style: AppText.label),
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.xs,
                        children: _noteChips.map((chip) {
                          final selected = _selectedChip == chip;

                          return ChoiceChip(
                            label: Text(chip),
                            selected: selected,
                            showCheckmark: true,
                            checkmarkColor: scheme.onPrimary,
                            selectedColor: scheme.primary,
                            backgroundColor: scheme.primaryContainer,
                            side: BorderSide.none,
                            labelStyle: AppText.caption.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.primary,
                            ),
                            onSelected: (value) {
                              setState(() {
                                _selectedChip = value ? chip : '';
                                if (value) _noteCtrl.clear();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpace.md),
                      AppTextField(
                        label: 'Catatan lain',
                        controller: _noteCtrl,
                        hint: 'Ketik jika tidak ada di pilihan di atas',
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          if (_selectedChip.isNotEmpty && value.isNotEmpty) {
                            setState(() => _selectedChip = '');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Kaki
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
                      label: _isEdit ? 'Simpan perubahan' : 'Simpan catatan',
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
