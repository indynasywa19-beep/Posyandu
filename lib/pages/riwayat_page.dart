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
import 'jadwal_page.dart';
import 'login_page.dart';
import 'pemeriksaan_page.dart';
import 'profil_page.dart';

class RiwayatPage extends StatefulWidget {
  final bool isKader;
  final bool onlyVaccinations;

  const RiwayatPage({
    super.key,
    this.isKader = false,
    this.onlyVaccinations = false,
  });

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

      final entries =
          <_HistoryEntry>[
            for (final item in examinations)
              _HistoryEntry(
                icon: Icons.medical_services_outlined,
                title: 'Pemeriksaan Gizi',
                childName:
                    childNames[item['anak_id']] ?? 'Anak tidak ditemukan',
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
                childName:
                    childNames[item['anak_id']] ?? 'Anak tidak ditemukan',
                date: item['tanggal']?.toString() ?? '',
                detail: 'Vaksin ${item['nama_vaksin'] ?? '-'}',
                note: item['keterangan']?.toString() ?? '',
                isVaccination: true,
              ),
          ]..sort((a, b) {
            final dateA = DateTime.tryParse(a.date);
            final dateB = DateTime.tryParse(b.date);
            if (dateA == null || dateB == null) return a.date.compareTo(b.date);
            return dateA.compareTo(dateB);
          });
      if (widget.onlyVaccinations) {
        entries.removeWhere((entry) => !entry.isVaccination);
      }

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

  void _onNavigationTap(BuildContext context, int index) {
    final page = widget.isKader
        ? switch (index) {
            0 => const HomeKaderPage(),
            1 => const DataAnakPage(isKader: true),
            2 => const PemeriksaanPage(openFormOnStart: true),
            3 => const JadwalPage(isKader: true),
            4 => const ProfilPage(),
            _ => null,
          }
        : switch (index) {
            0 => const HomeOrtuPage(),
            1 => const DataAnakPage(),
            2 => const JadwalPage(),
            3 => const ArtikelPage(),
            4 => const ProfilPage(),
            _ => null,
          };
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar dari akun: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Widget _buildKader(BuildContext context) {
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
          selectedIndex: -1,
          onTabSelected: (index) {
            final page = switch (index) {
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
          },
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
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
                              'Riwayat Global',
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Catatan pemeriksaan & imunisasi Posyandu',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      KaderLogoutButton(onPressed: _logout),
                    ],
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_off_outlined,
                              color: AppColors.kader,
                              size: 42,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadHistory,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF6D28D9),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum ada riwayat tercatat.',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Data pemeriksaan atau imunisasi akan muncul di sini.',
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
                    ..._entries.map((entry) {
                      final isVaccine = entry.isVaccination;
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isVaccine
                                      ? const Color(0xFFFFE4D6)
                                      : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  isVaccine
                                      ? Icons.vaccines_outlined
                                      : Icons.monitor_weight_outlined,
                                  color: isVaccine
                                      ? const Color(0xFFEA580C)
                                      : const Color(0xFF047857),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.childName,
                                          style: GoogleFonts.fredoka(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          entry.date,
                                          style: GoogleFonts.nunito(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.title,
                                      style: GoogleFonts.nunito(
                                        color: isVaccine
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFF047857),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.detail,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                    if (entry.note.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        entry.note,
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
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
    final accentColor = widget.isKader ? AppColors.kader : AppColors.parent;
    return Theme(
      data: widget.isKader ? AppTheme.kader : AppTheme.parent,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.onlyVaccinations
                ? 'Riwayat Imunisasi'
                : widget.isKader
                ? 'Riwayat Global'
                : 'Riwayat Anak',
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadHistory,
          color: accentColor,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.cloud_off_outlined,
                      color: accentColor,
                      size: 46,
                    ),
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
                    Text(
                      widget.onlyVaccinations
                          ? 'Belum ada catatan imunisasi.'
                          : 'Belum ada riwayat pemeriksaan.',
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
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: .1),
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
                                        color: AppColors.secondaryText,
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
                                          color: AppColors.secondaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                      ],
                    );
                  },
                ),
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: widget.isKader,
          selectedIndex: widget.isKader ? -1 : 1,
          onTap: (index) => _onNavigationTap(context, index),
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
  final bool isVaccination;

  const _HistoryEntry({
    required this.icon,
    required this.title,
    required this.childName,
    required this.date,
    required this.detail,
    required this.note,
    this.isVaccination = false,
  });
}
