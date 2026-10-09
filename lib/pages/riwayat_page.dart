import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPage extends StatefulWidget {
  final bool isKader;

  const RiwayatPage({super.key, this.isKader = false});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final _supabase = Supabase.instance.client;
  List<_HistoryEntry> _entries = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = _supabase.auth.currentUser;
    if (!widget.isKader && user == null) {
      setState(() {
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
      final List<Map<String, dynamic>> children;
      if (widget.isKader) {
        children = await _supabase.from('anak').select('id, nama');
      } else {
        children = await _supabase
            .from('anak')
            .select('id, nama')
            .eq('user_id', user!.id);
      }
      final childNames = <Object, String>{};
      for (final child in children) {
        final id = child['id'];
        if (id is Object) childNames[id] = child['nama']?.toString() ?? '-';
      }
      if (childNames.isEmpty) {
        if (!mounted) return;
        setState(() {
          _entries = [];
          _isLoading = false;
        });
        return;
      }

      final ids = childNames.keys.toList();
      final examinations = await _supabase
          .from('pemeriksaan')
          .select()
          .inFilter('anak_id', ids)
          .order('tanggal', ascending: true);
      final vaccinations = await _supabase
          .from('imunisasi')
          .select()
          .inFilter('anak_id', ids)
          .order('tanggal', ascending: true);

      final entries = <_HistoryEntry>[
        for (final item in examinations)
          _HistoryEntry(
            icon: Icons.medical_services_outlined,
            title: 'Pemeriksaan Gizi',
            childName: childNames[item['anak_id']] ?? 'Anak tidak ditemukan',
            date: item['tanggal']?.toString() ?? '',
            detail:
                'BB: ${item['berat_badan'] ?? '-'} kg • '
                'TB: ${item['tinggi_badan'] ?? '-'} cm',
            note: item['catatan']?.toString() ?? '',
          ),
        for (final item in vaccinations)
          _HistoryEntry(
            icon: Icons.vaccines_outlined,
            title: item['nama_vaksin']?.toString() ?? 'Imunisasi',
            childName: childNames[item['anak_id']] ?? 'Anak tidak ditemukan',
            date: item['tanggal']?.toString() ?? '',
            detail: 'Vaksin ${item['nama_vaksin'] ?? '-'}',
            note: item['keterangan']?.toString() ?? '',
          ),
      ]..sort((a, b) {
          final dateA = DateTime.tryParse(a.date);
          final dateB = DateTime.tryParse(b.date);
          if (dateA == null || dateB == null) return a.date.compareTo(b.date);
          return dateA.compareTo(dateB);
        });

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat riwayat pemeriksaan: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isKader
        ? const Color(0xFF173B72)
        : const Color(0xFF13835F);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Riwayat Anak'),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.cloud_off_outlined, color: accentColor, size: 46),
                  const SizedBox(height: 12),
                  Text(_loadError!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _loadHistory,
                    child: const Text('Coba lagi'),
                  ),
                ],
              )
            : _entries.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.history_rounded, color: accentColor, size: 52),
                  const SizedBox(height: 14),
                  const Text(
                    'Belum ada riwayat pemeriksaan.',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(entry.icon, color: accentColor),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.childName,
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.date,
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(entry.detail),
                              if (entry.note.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  entry.note,
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _HistoryEntry {
  final IconData icon;
  final String title;
  final String childName;
  final String date;
  final String detail;
  final String note;

  const _HistoryEntry({
    required this.icon,
    required this.title,
    required this.childName,
    required this.date,
    required this.detail,
    required this.note,
  });
}
