import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        _loadError = 'Gagal memuat data anak: $error';
        _isLoading = false;
      });
    }
  }

  void _showForm({Map<String, dynamic>? child}) {
    final nameController = TextEditingController(
      text: child?['nama'] as String? ?? '',
    );
    final nikController = TextEditingController(
      text: child?['nik'] as String? ?? '',
    );
    final birthDateController = TextEditingController(
      text: child?['tanggal_lahir'] as String? ?? '',
    );
    var gender = child?['jenis_kelamin'] as String? ?? 'Perempuan';
    var nikErrorText = _nikError(nikController.text);
    var isSaving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canSave =
              nameController.text.trim().isNotEmpty &&
              RegExp(r'^\d{16}$').hasMatch(nikController.text) &&
              birthDateController.text.isNotEmpty &&
              !isSaving;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(child == null ? 'Data Anak' : 'Ubah Data Anak'),
              leading: IconButton(
                tooltip: 'Kembali',
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftarkan si kecil',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Anak',
                      prefixIcon: Icon(Icons.child_care_outlined),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nikController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: InputDecoration(
                      labelText: 'NIK',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      errorText: nikErrorText,
                      counterText: '${nikController.text.length}/16',
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        nikErrorText = _nikError(value);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: birthDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Lahir',
                      hintText: 'Pilih tanggal lahir',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final parsedDate = DateTime.tryParse(
                        birthDateController.text,
                      );
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: parsedDate ?? now,
                        firstDate: DateTime(1900),
                        lastDate: now,
                      );
                      if (picked == null) return;
                      setDialogState(() {
                        birthDateController.text =
                            '${picked.year.toString().padLeft(4, '0')}-'
                            '${picked.month.toString().padLeft(2, '0')}-'
                            '${picked.day.toString().padLeft(2, '0')}';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jenis kelamin',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ChipSelector(
                          options: const ['Laki-laki', 'Perempuan'],
                          selected: gender,
                          roleColor: widget.isKader
                              ? AppColors.kader
                              : AppColors.parent,
                          softColor: widget.isKader
                              ? AppColors.kaderSoft
                              : AppColors.parentSoft,
                          onSelected: (value) =>
                              setDialogState(() => gender = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: FilledButton(
                onPressed: canSave
                    ? () async {
                        final user = _supabase.auth.currentUser;
                        if (user == null) {
                          _showMessage(
                            'Sesi login berakhir. Silakan masuk kembali.',
                            isError: true,
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        try {
                          final data = <String, dynamic>{
                            'nama': nameController.text.trim(),
                            'nik': nikController.text,
                            'tanggal_lahir': birthDateController.text,
                            'jenis_kelamin': gender,
                          };
                          if (child == null) {
                            await _supabase.from('anak').insert({
                              ...data,
                              'user_id': user.id,
                            });
                          } else {
                            await _supabase
                                .from('anak')
                                .update(data)
                                .eq('id', child['id']);
                          }
                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          _showMessage('Data anak berhasil disimpan.');
                          await _loadChildren();
                        } catch (error) {
                          if (!mounted || !dialogContext.mounted) return;
                          setDialogState(() => isSaving = false);
                          _showMessage(
                            'Gagal menyimpan data anak: $error',
                            isError: true,
                          );
                        }
                      }
                    : null,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Daftarkan anak'),
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      nameController.dispose();
      nikController.dispose();
      birthDateController.dispose();
    });
  }

  String? _nikError(String nik) {
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      return 'NIK harus terdiri dari 16 digit angka';
    }
    return null;
  }

  Future<void> _deleteChild(Map<String, dynamic> child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data anak?'),
        content: Text('Data ${child['nama']} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _supabase.from('anak').delete().eq('id', child['id']);
      _showMessage('Data anak berhasil dihapus.');
      await _loadChildren();
    } catch (error) {
      _showMessage('Gagal menghapus data anak: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      _showMessage('Gagal keluar dari akun: $error', isError: true);
    }
  }

  void _onNavigationTap(BuildContext context, int index) {
    final page = widget.isKader
        ? switch (index) {
            0 => const HomeKaderPage(),
            2 => const PemeriksaanPage(openFormOnStart: true),
            3 => const JadwalPage(isKader: true),
            4 => const ProfilPage(),
            _ => null,
          }
        : switch (index) {
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

  Widget _buildKader(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final visibleChildren = _children.where((child) {
      return query.isEmpty ||
          (child['nama']?.toString().toLowerCase().contains(query) ?? false) ||
          (child['nik']?.toString().contains(query) ?? false);
    }).toList();

    return Theme(
      data: AppTheme.kader.copyWith(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
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
            final page = switch (index) {
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
          child: RefreshIndicator(
            onRefresh: _loadChildren,
            color: AppColors.kader,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 28,
                          color: Color(0xFF0F172A),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monitoring Anak',
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Daftar anak terdaftar di Posyandu',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: AppColors.kader,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showForm(),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      KaderLogoutButton(onPressed: _logout),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari nama anak atau NIK',
                        hintStyle: GoogleFonts.nunito(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_children.length} anak',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      if (query.isNotEmpty)
                        Text(
                          '${visibleChildren.length} ditemukan',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kader,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.kader),
                      ),
                    )
                  else if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_off_outlined,
                              size: 42,
                              color: AppColors.kader,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadChildren,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (visibleChildren.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const ChildAvatar(
                              size: 56,
                              faceColor: Color(0xFFF9C5E2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              query.isEmpty
                                  ? 'Belum ada data anak di Posyandu.'
                                  : 'Tidak ada anak yang cocok dengan pencarian.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              query.isEmpty
                                  ? 'Tekan tombol + di kanan atas untuk mendaftar.'
                                  : 'Periksa kembali ejaan nama atau 16 digit NIK.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...visibleChildren.map((child) {
                      final name = child['nama'] as String? ?? 'Tanpa nama';
                      final gender = child['jenis_kelamin'] as String? ?? '-';
                      final birthDate = child['tanggal_lahir'] as String? ?? '-';
                      final nik = child['nik'] as String? ?? '-';
                      final isMale = gender.toLowerCase().contains('laki');

                      return Column(
                        children: [
                          Row(
                            children: [
                              ChildAvatar(
                                size: 44,
                                faceColor: isMale
                                    ? const Color(0xFFFFE78A)
                                    : const Color(0xFFF9C5E2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$gender • Lahir $birthDate\nNIK: $nik',
                                      style: GoogleFonts.nunito(
                                        color: const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: const Color(0xFFDBEAFE),
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _showForm(child: child),
                                  customBorder: const CircleBorder(),
                                  child: const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: const Color(0xFFFFE4E6),
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _deleteChild(child),
                                  customBorder: const CircleBorder(),
                                  child: const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFBE123C),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const KaderDashedDivider(),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isKader) {
      return _buildKader(context);
    }
    final color = widget.isKader
        ? AppColors.kader
        : AppColors.parent;
    final query = _searchQuery.trim().toLowerCase();
    final visibleChildren = _children.where((child) {
      return query.isEmpty ||
          (child['nama']?.toString().toLowerCase().contains(query) ?? false) ||
          (child['nik']?.toString().contains(query) ?? false);
    }).toList();
    return Theme(
      data: widget.isKader ? AppTheme.kader : AppTheme.parent,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.isKader ? 'Monitoring Anak' : 'Anak'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: color,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(widget.isKader ? 'Tambah Anak' : 'Tambah anak'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadChildren,
          color: color,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    Icon(Icons.cloud_off_outlined, size: 48, color: color),
                    const SizedBox(height: 12),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadChildren,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                  children: [
                    if (!widget.isKader) _parentProfileCard(color),
                    if (widget.isKader) ...[
                      TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Cari nama anak atau NIK',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Text(
                        widget.isKader
                            ? 'Anak terdaftar (${_children.length})'
                            : '${_children.length} anak terdaftar',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_children.isEmpty) ...[
                      const SizedBox(height: 22),
                      Center(child: ChildAvatar(size: 60, faceColor: Color(0xFFF9C5E2))),
                      const SizedBox(height: 12),
                      Text(
                        widget.isKader
                            ? 'Belum ada data anak di Posyandu.'
                            : 'Belum ada data anak',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isKader
                            ? 'Data yang didaftarkan orang tua akan tampil di sini.'
                            : 'Daftarkan identitas si kecil untuk mulai memantau.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.secondaryText),
                      ),
                      if (!widget.isKader) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _showForm(),
                          child: const Text('Tambahkan data anak'),
                        ),
                      ],
                    ] else if (visibleChildren.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'Tidak ada anak yang cocok dengan pencarian.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      ),
                    ] else
                      ...visibleChildren.map((child) {
                        final name = child['nama'] as String? ?? 'Tanpa nama';
                        final gender =
                            child['jenis_kelamin'] as String? ?? '-';
                        final birthDate =
                            child['tanggal_lahir'] as String? ?? '-';
                        final nik = child['nik'] as String? ?? '-';
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                              leading: ChildAvatar(
                                size: 42,
                                faceColor: name.hashCode.isEven
                                    ? const Color(0xFFFFE78A)
                                    : const Color(0xFFF9C5E2),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '$gender • Lahir $birthDate\nNIK: $nik',
                              ),
                              isThreeLine: true,
                              trailing: widget.isKader
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Ubah',
                                          onPressed: () =>
                                              _showForm(child: child),
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: color,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Hapus',
                                          onPressed: () => _deleteChild(child),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.logoutForeground,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.secondaryText,
                                    ),
                            ),
                            const Divider(
                              color: AppColors.divider,
                              height: 1,
                              indent: 58,
                            ),
                          ],
                        );
                      }),
                    if (!widget.isKader)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          onPressed: () => _showForm(),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Tambah anak baru'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color.withValues(alpha: .4)),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: widget.isKader,
          selectedIndex: 1,
          onTap: (index) => _onNavigationTap(context, index),
        ),
      ),
    );
  }

  Widget _parentProfileCard(Color color) {
    final user = _supabase.auth.currentUser;
    final rawName =
        user?.userMetadata?['display_name'] ?? user?.userMetadata?['full_name'];
    final parentName = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Orang Tua / Wali';
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parentSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const ChildAvatar(
            size: 42,
            faceColor: Color(0xFFF9C5E2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Orang Tua / Wali',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
                Text(
                  user?.email ?? '-',
                  style: const TextStyle(
                    color: AppColors.parent,
                    fontSize: 12,
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
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}
