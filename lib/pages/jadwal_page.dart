import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          final ready = dateController.text.isNotEmpty &&
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
                      initialDate: DateTime.tryParse(dateController.text) ?? now,
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
                onPressed: isSaving
                    ? null
                    : () => Navigator.pop(dialogContext),
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

  @override
  Widget build(BuildContext context) {
    final color = widget.isKader
        ? const Color(0xFF173B72)
        : const Color(0xFF13835F);
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Jadwal Posyandu'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isKader)
            IconButton(
              tooltip: 'Tambah jadwal',
              onPressed: () => _editSchedule(),
              icon: const Icon(Icons.add_box_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedules,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Jadwal Bulan ${_monthNames[now.month - 1]} ${now.year}',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              widget.isKader
                  ? 'Kelola informasi kegiatan Posyandu.'
                  : 'Informasi kegiatan Posyandu untuk keluarga.',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 18),
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kegiatan Posyandu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$date • $time',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isKader) ...[
                            IconButton(
                              tooltip: 'Edit jadwal',
                              onPressed: () => _editSchedule(schedule: schedule),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Hapus jadwal',
                              onPressed: () => _deleteSchedule(schedule),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 26),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(location)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 14),
            const Text(
              'Kegiatan Layanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _activity(Icons.monitor_weight_outlined, 'Penimbangan'),
            _activity(Icons.height_rounded, 'Pengukuran tinggi badan'),
            _activity(Icons.vaccines_outlined, 'Imunisasi'),
            _activity(Icons.medical_services_outlined, 'Pemeriksaan kesehatan'),
          ],
        ),
      ),
    );
  }

  Widget _activity(IconData icon, String title) {
    final color = widget.isKader
        ? const Color(0xFF173B72)
        : const Color(0xFF13835F);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
