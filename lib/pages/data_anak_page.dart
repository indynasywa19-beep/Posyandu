import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../utils/validators.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'artikel_page.dart';
import 'home_kader_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'pemeriksaan_page.dart';
import 'perkembangan_page.dart';
import 'profil_page.dart';

class DataAnakPage extends StatefulWidget {
  final bool isKader;

  const DataAnakPage({super.key, this.isKader = false});

  @override
  State<DataAnakPage> createState() => _DataAnakPageState();
}

class _DataAnakPageState extends State<DataAnakPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  String? _loadError;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
  Future<void> _loadChildren() async {
    final user = _supabase.auth.currentUser;

    if (!widget.isKader && user == null) {
      setState(() {
        _children = [];
        _loadError = 'Sesi login tidak ditemukan. Silakan masuk kembali.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final List<Map<String, dynamic>> rows;

      if (widget.isKader) {
        rows = await _supabase.from('anak').select().order('nama');
      } else {
        rows = await _supabase
            .from('anak')
            .select()
            .eq('user_id', user!.id)
            .order('nama');
      }

      if (!mounted) return;

      setState(() {
        _children = rows;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = friendlyError(
          error,
          fallback: 'Data anak belum bisa dimuat. Coba lagi sebentar lagi.',
        );
        _isLoading = false;
      });
    }
  }

  void _openChildDetail(Map<String, dynamic> child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PerkembanganPage(isKader: widget.isKader, anakId: child['id']),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _tanggalTampil(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final date = DateTime.tryParse(iso);
    return date == null ? iso : tanggalLengkap(date);
  }

  // ---------------------------------------------------------------------------
  // FORM TAMBAH / UBAH
  // ---------------------------------------------------------------------------
  Future<void> _showForm({Map<String, dynamic>? child}) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Theme(
        data: AppTheme.forRole(isKader: widget.isKader),
        child: _ChildFormSheet(child: child),
      ),
    );

    if (!mounted || message == null) return;

    _showMessage(message);
    await _loadChildren();
  }

  // ---------------------------------------------------------------------------
  // HAPUS
  // ---------------------------------------------------------------------------
  Future<void> _deleteChild(Map<String, dynamic> child) async {
    final nama = child['nama']?.toString() ?? 'anak ini';

    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus data anak?',
      message: 'Data $nama akan dihapus dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _supabase.from('anak').delete().eq('id', child['id']);

      _showMessage('Data $nama dihapus.');
      await _loadChildren();
    } catch (error) {
      _showMessage(
        friendlyError(
          error,
          fallback: 'Data anak belum bisa dihapus. Coba lagi.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // KELUAR AKUN
  // ---------------------------------------------------------------------------
  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk membuka SI-POSYANDU.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      _showMessage(
        friendlyError(
          error,
          fallback: 'Belum bisa keluar dari akun. Coba lagi.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI (Orang Tua)
  // ---------------------------------------------------------------------------
  void _onParentNavigationTap(BuildContext context, int index) {
    final Widget? page = switch (index) {
      0 => const HomeOrtuPage(),
      2 => const JadwalPage(),
      3 => const ArtikelPage(),
      4 => const ProfilPage(),
      _ => null,
    };

    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  List<Map<String, dynamic>> get _visibleChildren {
    final query = _searchQuery.trim().toLowerCase();

    return _children.where((child) {
      return query.isEmpty ||
          (child['nama']?.toString().toLowerCase().contains(query) ?? false) ||
          (child['nik']?.toString().contains(query) ?? false);
    }).toList();
  }

  // ===========================================================================
  // TAMPILAN KADER
  // ===========================================================================
  Widget _buildKader(BuildContext context) {
    final visible = _visibleChildren;
    final query = _searchQuery.trim();

    return Theme(
      data: AppTheme.kader,
      child: Scaffold(
        floatingActionButton: KaderCenterFab(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PemeriksaanPage(openFormOnStart: true),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: 1,
          onTabSelected: (index) {
            final Widget? page = switch (index) {
              0 => const HomeKaderPage(),
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
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.sm,
                ),
                child: KaderTopBar(
                  title: 'Monitoring Anak',
                  subtitle: 'Daftar anak terdaftar di Posyandu',
                  onBack: () => Navigator.maybePop(context),
                  trailing: KaderLogoutButton(onPressed: _logout),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                child: AppSearchField(
                  hint: 'Cari nama anak atau NIK',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.sm,
                  AppSpace.page,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        query.isEmpty
                            ? '${_children.length} anak terdaftar'
                            : '${visible.length} dari ${_children.length} anak',
                        style: AppText.label.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Tambah anak',
                      icon: Icons.add_rounded,
                      expand: false,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _showForm(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Expanded(child: _buildKaderBody(visible, query)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKaderBody(List<Map<String, dynamic>> visible, String query) {
    if (_isLoading) {
      return const LoadingState(message: 'Memuat data anak');
    }

    if (_loadError != null) {
      return ErrorState(message: _loadError!, onRetry: _loadChildren);
    }

    if (visible.isEmpty) {
      return query.isEmpty
          ? EmptyState(
              icon: Icons.child_care_rounded,
              title: 'Belum ada data anak di Posyandu',
              message:
                  'Anak yang didaftarkan orang tua akan tampil di sini. Anda juga bisa mendaftarkan anak lewat tombol Tambah anak.',
              actionLabel: 'Tambah anak',
              onAction: () => _showForm(),
            )
          : const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Tidak ada anak yang cocok',
              message: 'Periksa kembali ejaan nama atau 16 digit NIK.',
            );
    }

    return RefreshIndicator(
      onRefresh: _loadChildren,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.xs,
          AppSpace.page,
          AppSpace.xl,
        ),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
        itemBuilder: (context, index) {
          final child = visible[index];
          final name = child['nama'] as String? ?? 'Tanpa nama';

          return AppCard(
            onTap: () => _openChildDetail(child),
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(name: name, size: 44),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _ChildInfo(
                    name: name,
                    gender: child['jenis_kelamin'] as String? ?? '-',
                    birthDate: _tanggalTampil(child['tanggal_lahir'] as String?),
                    nik: child['nik'] as String? ?? '-',
                    showDetailHint: true,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu untuk $name',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showForm(child: child);
                    } else {
                      _deleteChild(child);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: AppSpace.md),
                          Text('Ubah data'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppStatus.danger.foreground,
                          ),
                          const SizedBox(width: AppSpace.md),
                          Text(
                            'Hapus data',
                            style: TextStyle(color: AppStatus.danger.foreground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAMPILAN ORANG TUA
  // ===========================================================================
  Widget _buildParent(BuildContext context) {
    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Anak')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: AppColors.parent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah anak'),
        ),
        body: _buildParentBody(),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 1,
          onTap: (index) => _onParentNavigationTap(context, index),
        ),
      ),
    );
  }

  Widget _buildParentBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Memuat data anak');
    }

    if (_loadError != null) {
      return ErrorState(message: _loadError!, onRetry: _loadChildren);
    }

    return RefreshIndicator(
      onRefresh: _loadChildren,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.md,
          AppSpace.page,
          96,
        ),
        children: [
          _parentProfileCard(),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(
            title: 'Anak terdaftar',
            subtitle: '${_children.length} anak',
          ),
          const SizedBox(height: AppSpace.md),
          if (_children.isEmpty)
            EmptyState(
              icon: Icons.child_care_rounded,
              title: 'Belum ada data anak',
              message: 'Daftarkan identitas si kecil untuk mulai memantau.',
              actionLabel: 'Tambahkan data anak',
              onAction: () => _showForm(),
            )
          else
            for (var i = 0; i < _children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.md),
              _parentChildCard(_children[i]),
            ],
        ],
      ),
    );
  }

  Widget _parentChildCard(Map<String, dynamic> child) {
    final name = child['nama'] as String? ?? 'Tanpa nama';

    return AppCard(
      onTap: () => _openChildDetail(child),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(name: name, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _ChildInfo(
              name: name,
              gender: child['jenis_kelamin'] as String? ?? '-',
              birthDate: _tanggalTampil(child['tanggal_lahir'] as String?),
              nik: child['nik'] as String? ?? '-',
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: AppSpace.sm),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _parentProfileCard() {
    final user = _supabase.auth.currentUser;
    final parentName = displayNameFromUser(
      user,
      fallback: 'Orang Tua / Wali',
    );

    return AppCard(
      color: AppColors.parentTint,
      child: Row(
        children: [
          InitialsAvatar(name: parentName, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parentName, style: AppText.subtitle),
                Text('Orang Tua / Wali', style: AppText.caption),
                Text(
                  user?.email ?? '-',
                  style: AppText.caption.copyWith(
                    color: AppColors.parent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilPage()),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isKader ? _buildKader(context) : _buildParent(context);
  }
}

// =============================================================================
// RINCIAN ANAK (dipakai di daftar Kader dan Orang Tua)
// =============================================================================
class _ChildInfo extends StatelessWidget {
  final String name;
  final String gender;
  final String birthDate;
  final String nik;
  final bool showDetailHint;

  const _ChildInfo({
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.nik,
    this.showDetailHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppText.subtitle),
        const SizedBox(height: 2),
        Text('$gender • Lahir $birthDate', style: AppText.caption),
        Text('NIK: $nik', style: AppText.caption),
        if (showDetailHint) ...[
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Lihat perkembangan',
                style: AppText.caption.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// LEMBAR FORM
// =============================================================================
class _ChildFormSheet extends StatefulWidget {
  final Map<String, dynamic>? child;

  const _ChildFormSheet({required this.child});

  @override
  State<_ChildFormSheet> createState() => _ChildFormSheetState();
}

class _ChildFormSheetState extends State<_ChildFormSheet> {
  static const _genders = ['Laki-laki', 'Perempuan'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nikCtrl;

  DateTime? _birthDate;
  String _gender = '';

  bool _isSaving = false;
  bool _autoValidate = false;
  String? _birthError;
  String? _genderError;
  String? _errorMessage;

  bool get _isEdit => widget.child != null;

  @override
  void initState() {
    super.initState();

    final c = widget.child;

    _nameCtrl = TextEditingController(text: c?['nama'] as String? ?? '');
    _nikCtrl = TextEditingController(text: c?['nik'] as String? ?? '');

    final rawBirth = c?['tanggal_lahir'] as String?;
    if (rawBirth != null && rawBirth.isNotEmpty) {
      _birthDate = DateTime.tryParse(rawBirth);
    }

    // Anak baru: jenis kelamin TIDAK terisi bawaan (sebelumnya "Perempuan").
    final rawGender = c?['jenis_kelamin'] as String?;
    if (rawGender != null && _genders.contains(rawGender)) {
      _gender = rawGender;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    super.dispose();
  }

  String? _validateNik(String? value) {
    final nik = value ?? '';
    if (nik.isEmpty) return 'NIK wajib diisi.';
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      return 'NIK harus terdiri dari 16 digit angka (sekarang ${nik.length}).';
    }
    return null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    var initial = _birthDate ?? now;
    if (initial.isAfter(now)) initial = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
        _birthError = null;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final formOk = _formKey.currentState!.validate();
    final birthOk = _birthDate != null;
    final genderOk = _gender.isNotEmpty;

    setState(() {
      _birthError = birthOk ? null : 'Pilih tanggal lahir.';
      _genderError = genderOk ? null : 'Pilih jenis kelamin.';
      if (!formOk || !birthOk || !genderOk) _autoValidate = true;
    });

    if (!formOk || !birthOk || !genderOk) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(
        () => _errorMessage = 'Sesi login berakhir. Silakan masuk kembali.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final birth = _birthDate!;
    final data = <String, dynamic>{
      'nama': _nameCtrl.text.trim(),
      'nik': _nikCtrl.text,
      'tanggal_lahir':
          '${birth.year.toString().padLeft(4, '0')}-'
          '${birth.month.toString().padLeft(2, '0')}-'
          '${birth.day.toString().padLeft(2, '0')}',
      'jenis_kelamin': _gender,
    };

    try {
      final supabase = Supabase.instance.client;

      if (widget.child == null) {
        await supabase.from('anak').insert({...data, 'user_id': user.id});
      } else {
        await supabase
            .from('anak')
            .update(data)
            .eq('id', widget.child!['id']);
      }

      if (!mounted) return;

      final nama = data['nama'] as String;
      Navigator.pop(
        context,
        _isEdit
            ? 'Perubahan data $nama disimpan.'
            : '$nama berhasil didaftarkan.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = friendlyError(
          error,
          fallback:
              'Data anak belum tersimpan. Periksa koneksi internet, lalu coba lagi.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height;

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
                            _isEdit ? 'Ubah data anak' : 'Daftarkan si kecil',
                            style: AppText.title,
                          ),
                        ),
                        Text(
                          'Isi identitas anak dengan teliti.',
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
                      AppTextField(
                        label: 'Nama anak',
                        controller: _nameCtrl,
                        prefixIcon: Icons.child_care_outlined,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => validateRequired(v, 'Nama anak'),
                      ),
                      const SizedBox(height: AppSpace.lg),

                      AppTextField(
                        label: 'NIK',
                        controller: _nikCtrl,
                        helper: 'Terdiri dari 16 digit angka.',
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 16,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateNik,
                      ),
                      const SizedBox(height: AppSpace.md),

                      Text('Tanggal lahir', style: AppText.label),
                      const SizedBox(height: 6),
                      AppPickerTile(
                        icon: Icons.calendar_month_outlined,
                        value: _birthDate == null
                            ? 'Pilih tanggal lahir'
                            : tanggalLengkap(_birthDate!),
                        isPlaceholder: _birthDate == null,
                        semanticLabel: _birthDate == null
                            ? 'Tanggal lahir belum dipilih. Pilih tanggal lahir'
                            : 'Tanggal lahir ${tanggalLengkap(_birthDate!)}. Ubah tanggal',
                        onTap: _pickBirthDate,
                      ),
                      if (_birthError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _birthError!,
                          style: AppText.caption.copyWith(
                            color: AppStatus.danger.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.lg),

                      Text('Jenis kelamin', style: AppText.label),
                      const SizedBox(height: AppSpace.sm),
                      ChoiceChipGroup(
                        options: _genders,
                        selected: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                            if (value.isNotEmpty) _genderError = null;
                          });
                        },
                      ),
                      if (_genderError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _genderError!,
                          style: AppText.caption.copyWith(
                            color: AppStatus.danger.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                      label: _isEdit ? 'Simpan perubahan' : 'Daftarkan anak',
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
