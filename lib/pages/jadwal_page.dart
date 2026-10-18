import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'artikel_page.dart';
import 'data_anak_page.dart';
import 'home_kader_page.dart';
import 'home_ortu_page.dart';
import 'login_page.dart';
import 'pemeriksaan_page.dart';
import 'profil_page.dart';

class JadwalPage extends StatefulWidget {
  final bool isKader;

  const JadwalPage({super.key, this.isKader = false});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  String? _loadError;

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final schedules = await _supabase
          .from('jadwal')
          .select()
          .order('tanggal');
      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat jadwal: $error';
        _isLoading = false;
      });
    }
  }

  void _editSchedule({Map<String, dynamic>? schedule}) {
    final dateController = TextEditingController(
      text: schedule?['tanggal'] as String? ?? '',
    );
    final timeController = TextEditingController(
      text: schedule?['waktu'] as String? ?? '',
    );
    final locationController = TextEditingController(
      text: schedule?['lokasi'] as String? ?? '',
    );
    var isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final ready =
              dateController.text.isNotEmpty &&
              timeController.text.isNotEmpty &&
              locationController.text.trim().isNotEmpty &&
              !isSaving;
          return AlertDialog(
            title: Text(schedule == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final selected = await showDatePicker(
                      context: dialogContext,
                      initialDate:
                          DateTime.tryParse(dateController.text) ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (selected == null) return;
                    setDialogState(() {
                      dateController.text =
                          '${selected.year.toString().padLeft(4, '0')}-'
                          '${selected.month.toString().padLeft(2, '0')}-'
                          '${selected.day.toString().padLeft(2, '0')}';
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Waktu',
                    prefixIcon: Icon(Icons.access_time_rounded),
                  ),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selected == null) return;
                    setDialogState(() {
                      timeController.text =
                          '${selected.hour.toString().padLeft(2, '0')}:'
                          '${selected.minute.toString().padLeft(2, '0')}';
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: ready
                    ? () async {
                        setDialogState(() => isSaving = true);
                        final data = {
                          'tanggal': dateController.text,
                          'waktu': timeController.text,
                          'lokasi': locationController.text.trim(),
                        };
                        try {
                          if (schedule == null) {
                            await _supabase.from('jadwal').insert(data);
                          } else {
                            await _supabase
                                .from('jadwal')
                                .update(data)
                                .eq('id', schedule['id']);
                          }
                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _showMessage('Jadwal berhasil disimpan.');
                          await _loadSchedules();
                        } catch (error) {
                          if (!mounted || !dialogContext.mounted) return;
                          setDialogState(() => isSaving = false);
                          _showMessage(
                            'Gagal menyimpan jadwal: $error',
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
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      dateController.dispose();
      timeController.dispose();
      locationController.dispose();
    });
  }

  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jadwal?'),
        content: const Text('Jadwal ini akan dihapus dari Posyandu.'),
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
      await _supabase.from('jadwal').delete().eq('id', schedule['id']);
      _showMessage('Jadwal berhasil dihapus.');
      await _loadSchedules();
    } catch (error) {
      _showMessage('Gagal menghapus jadwal: $error', isError: true);
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
      await Supabase.instance.client.auth.signOut();
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
            1 => const DataAnakPage(isKader: true),
            2 => const PemeriksaanPage(openFormOnStart: true),
            4 => const ProfilPage(),
            _ => null,
          }
        : switch (index) {
            0 => const HomeOrtuPage(),
            1 => const DataAnakPage(),
            3 => const ArtikelPage(),
            4 => const ProfilPage(),
            _ => null,
          };
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  Widget _buildKader(BuildContext context) {
    final now = DateTime.now();
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
          selectedIndex: 2,
          onTabSelected: (index) {
            final page = switch (index) {
              0 => const HomeKaderPage(),
              1 => const DataAnakPage(isKader: true),
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
            onRefresh: _loadSchedules,
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
                              'Jadwal Posyandu',
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_monthNames[now.month - 1]} ${now.year}',
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
                          onTap: () => _editSchedule(),
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
                  const KaderInfoPill(
                    icon: Icons.edit_note_rounded,
                    message: 'Kamu bisa tambah, ubah & hapus jadwal',
                  ),
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.kader),
                      ),
                    )
                  else if (_loadError != null)
                    _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      message: _loadError!,
                      color: AppColors.kader,
                      onRetry: _loadSchedules,
                    )
                  else if (_schedules.isEmpty)
                    _EmptyState(
                      icon: Icons.event_busy_outlined,
                      message: 'Belum ada jadwal Posyandu yang tersedia.',
                      color: AppColors.kader,
                      onRetry: _loadSchedules,
                    )
                  else
                    ..._schedules.map((schedule) {
                      final date = schedule['tanggal'] as String? ?? '-';
                      final time = schedule['waktu'] as String? ?? '-';
                      final location = schedule['lokasi'] as String? ?? '-';
                      final parsedDate = DateTime.tryParse(date);
                      final day = parsedDate == null
                          ? date
                          : '${parsedDate.day.toString().padLeft(2, '0')}\n'
                                '${_monthNames[parsedDate.month - 1].substring(0, 3)}';
                      return Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFFB45309),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Posyandu',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$location · $time',
                                      style: GoogleFonts.nunito(
                                        color: const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
                                  onTap: () =>
                                      _editSchedule(schedule: schedule),
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
                                  onTap: () => _deleteSchedule(schedule),
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
    final color = widget.isKader ? AppColors.kader : AppColors.parent;
    final now = DateTime.now();
    return Theme(
      data: widget.isKader ? AppTheme.kader : AppTheme.parent,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Jadwal Posyandu'),
          actions: [
            if (widget.isKader)
              IconButton(
                tooltip: 'Tambah jadwal',
                onPressed: () => _editSchedule(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.kader,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            const SizedBox(width: 12),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadSchedules,
          color: color,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Text(
                'Jadwal Posyandu',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_monthNames[now.month - 1]} ${now.year}',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              if (!widget.isKader) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.parentSoft,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: AppColors.parent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Hanya bisa dilihat · dibuat oleh Kader',
                        style: TextStyle(
                          color: AppColors.parent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Kelola jadwal dan lokasi kegiatan Posyandu.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ],
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _EmptyState(
                  icon: Icons.cloud_off_outlined,
                  message: _loadError!,
                  color: color,
                  onRetry: _loadSchedules,
                )
              else if (_schedules.isEmpty)
                _EmptyState(
                  icon: Icons.event_busy_outlined,
                  message: 'Belum ada jadwal Posyandu yang tersedia.',
                  color: color,
                  onRetry: _loadSchedules,
                )
              else
                ..._schedules.map((schedule) {
                  final date = schedule['tanggal'] as String? ?? '-';
                  final time = schedule['waktu'] as String? ?? '-';
                  final location = schedule['lokasi'] as String? ?? '-';
                  final parsedDate = DateTime.tryParse(date);
                  final day = parsedDate == null
                      ? date
                      : '${parsedDate.day.toString().padLeft(2, '0')}\n'
                            '${_monthNames[parsedDate.month - 1].substring(0, 3)}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posyandu',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$location · $time',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isKader) ...[
                              IconButton(
                                tooltip: 'Ubah jadwal',
                                onPressed: () =>
                                    _editSchedule(schedule: schedule),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.kaderMid,
                                  foregroundColor: AppColors.kader,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Hapus jadwal',
                                onPressed: () => _deleteSchedule(schedule),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.logoutBackground,
                                  foregroundColor: AppColors.logoutForeground,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _DashedDivider(),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 14),
              const Text(
                'Kegiatan Layanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _activity(Icons.monitor_weight_outlined, 'Penimbangan'),
              _activity(Icons.height_rounded, 'Pengukuran tinggi badan'),
              _activity(Icons.vaccines_outlined, 'Imunisasi'),
              _activity(
                Icons.medical_services_outlined,
                'Pemeriksaan kesehatan',
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: widget.isKader,
          selectedIndex: widget.isKader ? 3 : 2,
          onTap: (index) => _onNavigationTap(context, index),
        ),
      ),
    );
  }

  Widget _activity(IconData icon, String title) {
    final color = widget.isKader ? AppColors.kader : AppColors.parent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 7).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => const SizedBox(
                width: 3,
                height: 1,
                child: ColoredBox(color: AppColors.divider),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.color,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 42),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
