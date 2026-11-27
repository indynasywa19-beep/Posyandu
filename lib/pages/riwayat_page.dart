import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'data_anak_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'perkembangan_page.dart';
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
  bool _noChildren = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
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
      final List children;

      if (widget.isKader) {
        children = await _supabase.from('anak').select('id, nama');
      } else {
        children = await _supabase
            .from('anak')
            .select('id, nama')
            .eq('user_id', user!.id);
      }

      final Map childNames = {};
      for (final child in children) {
        final id = child['id'];
        if (id != null) {
          childNames[id.toString()] = child['nama']?.toString() ?? '-';
        }
      }

      if (childNames.isEmpty) {
        if (!mounted) return;
        setState(() {
          _entries = [];
          _noChildren = true;
          _isLoading = false;
        });
        return;
      }

      final ids = children.map((c) => c['id']).toList();

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

      String measure(Object? value, String unit) =>
          value == null ? '-' : '$value $unit';

      final List<_HistoryEntry> entries = [
        for (final item in examinations)
          _HistoryEntry(
            isVaccination: false,
            childId: item['anak_id'],
            childName:
                childNames[item['anak_id']?.toString()]?.toString() ??
                'Anak tidak ditemukan',
            date: item['tanggal']?.toString() ?? '',
            detail:
                'Berat ${measure(item['berat_badan'], 'kg')} · '
                'Tinggi ${measure(item['tinggi_badan'], 'cm')}',
            note: item['catatan']?.toString() ?? '',
          ),
        for (final item in vaccinations)
          _HistoryEntry(
            isVaccination: true,
            childId: item['anak_id'],
            childName:
                childNames[item['anak_id']?.toString()]?.toString() ??
                'Anak tidak ditemukan',
            date: item['tanggal']?.toString() ?? '',
            detail: item['nama_vaksin']?.toString() ?? 'Imunisasi',
            note: item['keterangan']?.toString() ?? '',
          ),
      ];

      entries.sort((a, b) {
        final dateA = DateTime.tryParse(a.date);
        final dateB = DateTime.tryParse(b.date);
        if (dateA == null || dateB == null) return b.date.compareTo(a.date);
        return dateB.compareTo(dateA);
      });

      if (widget.onlyVaccinations) {
        entries.removeWhere((entry) => !entry.isVaccination);
      }

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _noChildren = false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = friendlyError(
          error,
          fallback: 'Riwayat belum bisa dimuat. Coba lagi sebentar lagi.',
        );
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI (Orang Tua)
  // ---------------------------------------------------------------------------
  void _onParentNavigationTap(BuildContext context, int index) {
    if (index == 3) return;
    final Widget? page = switch (index) {
      0 => const HomeOrtuPage(),
      1 => const DataAnakPage(),
      2 => const JadwalPage(),
      4 => const ProfilPage(),
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
  // ISI BERSAMA
  // ---------------------------------------------------------------------------
  Widget _scrollableState(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildBody({required bool isKader}) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingState(message: 'Memuat riwayat'),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorState(
          title: 'Riwayat belum bisa dimuat',
          message: _loadError!,
          onRetry: _loadHistory,
        ),
      );
    }

    if (_entries.isEmpty) {
      final EmptyState empty;

      if (_noChildren) {
        empty = EmptyState(
          icon: Icons.child_care_rounded,
          title: 'Belum ada data anak',
          message: widget.isKader
              ? 'Riwayat akan muncul setelah ada anak yang terdaftar di Posyandu.'
              : 'Daftarkan anak di menu Anak untuk melihat riwayatnya.',
        );
      } else {
        empty = EmptyState(
          icon: widget.onlyVaccinations
              ? Icons.vaccines_outlined
              : Icons.history_rounded,
          title: widget.onlyVaccinations
              ? 'Belum ada catatan imunisasi'
              : 'Belum ada riwayat tercatat',
          message: widget.isKader
              ? 'Data pemeriksaan dan imunisasi akan muncul di sini.'
              : 'Catatan akan muncul setelah Kader mencatat pemeriksaan atau imunisasi anak Anda.',
        );
      }

      if (isKader) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: empty,
        );
      }

      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: _scrollableState(empty),
      );
    }

    final List<Widget> children = [];
    int? lastKey;

    for (final entry in _entries) {
      final date = DateTime.tryParse(entry.date);
      final key = date == null ? -1 : date.year * 100 + date.month;

      if (key != lastKey) {
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: lastKey == null ? 0 : AppSpace.lg,
              bottom: AppSpace.sm,
            ),
            child: Semantics(
              header: true,
              child: Text(
                date == null
                    ? 'Tanggal tidak diketahui'
                    : '${bulanLengkap(date.month)} ${date.year}',
                style: AppText.label.copyWith(color: AppColors.secondaryText),
              ),
            ),
          ),
        );
        lastKey = key;
      } else {
        children.add(const SizedBox(height: AppSpace.md));
      }

      children.add(
        _HistoryCard(
          entry: entry,
          dateText: date == null ? entry.date : tanggalLengkap(date),
          isKader: isKader,
        ),
      );
    }

    if (isKader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.lg,
          AppSpace.page,
          100,
        ),
        children: children,
      ),
    );
  }

  // ===========================================================================
  // TAMPILAN KADER
  // ===========================================================================
  Widget _buildKader(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return KaderWebScaffold(
      activeIndex: 5,
      breadcrumb: 'Beranda / Riwayat Global',
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider),
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Global Posyandu',
                          style: AppText.title.copyWith(
                            color: AppColors.primaryNavy,
                            fontSize: isMobile ? 17 : 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading || _loadError != null
                              ? 'Catatan pemeriksaan & imunisasi Posyandu'
                              : '${_entries.length} catatan pemeriksaan & imunisasi tercatat',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Muat ulang data',
                    onPressed: _loadHistory,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: AppSpace.md),
              _buildBody(isKader: true),
            ],
          ),
        ),
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
        appBar: AppBar(
          title: Text(
            widget.onlyVaccinations ? 'Riwayat Imunisasi' : 'Riwayat Anak',
          ),
        ),
        body: _buildBody(isKader: false),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 3,
          onTap: (index) => _onParentNavigationTap(context, index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isKader ? _buildKader(context) : _buildParent(context);
  }
}

// =============================================================================
// PENJELASAN JENIS VAKSIN & VITAMIN
// =============================================================================
String _vaccineDescription(String vaccineName) {
  final v = vaccineName.toLowerCase();
  if (v.contains('hb-0') || v.contains('hepatitis')) {
    return 'Vaksin Hepatitis B dosis pertama untuk melindungi bayi sejak lahir dari infeksi virus Hepatitis B yang menyerang organ hati.';
  }
  if (v.contains('bcg')) {
    return 'Vaksin BCG melindungi bayi dan anak dari penyakit Tuberkulosis (TBC) berat, termasuk radang selaput otak akibat TBC.';
  }
  if (v.contains('polio')) {
    return 'Vaksin Polio mencegah infeksi virus polio yang dapat menyebabkan kelumpuhan permanen pada anak.';
  }
  if (v.contains('dpt')) {
    return 'Vaksin kombinasi untuk mencegah 5 penyakit sekaligus: Difteri, Pertusis (batuk rejan), Tetanus, Hepatitis B, serta infeksi Hib (radang paru & selaput otak).';
  }
  if (v.contains('campak') || v.contains('mr')) {
    return 'Vaksin Campak / MR melindungi anak dari penularan penyakit campak dan rubella yang dapat menimbulkan komplikasi radang paru maupun radang otak.';
  }
  if (v.contains('vitamin a') || v.contains('vit a')) {
    return 'Suplemen Vitamin A dosis tinggi untuk menjaga kesehatan mata, meningkatkan daya tahan tubuh terhadap infeksi, dan mendukung pertumbuhan sel anak.';
  }
  if (v.contains('pcv')) {
    return 'Vaksin Pneumokokus (PCV) melindungi anak dari infeksi bakteri penyebab pneumonia (radang paru-paru) dan meningitis.';
  }
  if (v.contains('rotavirus')) {
    return 'Vaksin Rotavirus mencegah diare berat akibat infeksi rotavirus yang sering menyebabkan dehidrasi pada bayi dan balita.';
  }
  return 'Pemberian imunisasi/suplemen kesehatan sesuai jadwal Posyandu untuk meningkatkan daya tahan tubuh dan melindungi anak dari penyakit menular.';
}

// =============================================================================
// KARTU RIWAYAT (DAPAT DIKLIK UNTUK DETAIL LENGKAP)
// =============================================================================
class _HistoryCard extends StatelessWidget {
  final _HistoryEntry entry;
  final String dateText;
  final bool isKader;

  const _HistoryCard({
    required this.entry,
    required this.dateText,
    required this.isKader,
  });

  void _showDetailSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVaccine = entry.isVaccination;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVaccine
                        ? Icons.vaccines_rounded
                        : Icons.monitor_weight_rounded,
                    color: scheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVaccine
                            ? 'Detail Imunisasi / Vitamin'
                            : 'Detail Pemeriksaan Gizi',
                        style: AppText.caption.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.detail,
                        style: AppText.title.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.divider),
            ),
            _detailRow('Nama Anak', entry.childName),
            const SizedBox(height: 10),
            _detailRow('Tanggal Layanan', dateText),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVaccine
                        ? 'Manfaat & Keterangan:'
                        : 'Keterangan Pemeriksaan:',
                    style: AppText.label.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVaccine
                        ? _vaccineDescription(entry.detail)
                        : 'Hasil penimbangan berat badan dan pengukuran tinggi badan anak yang dicatat oleh Kader Posyandu untuk memantau status gizi.',
                    style: AppText.body.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan dari Kader:',
                      style: AppText.label.copyWith(
                        fontSize: 13,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.note,
                      style: AppText.body.copyWith(
                        color: AppColors.text,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isVaccine) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerkembanganPage(
                          isKader: isKader,
                          anakId: entry.childId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.show_chart_rounded, size: 18),
                  label: const Text('Lihat Grafik di KMS Digital'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.caption),
        Text(
          value,
          style: AppText.label.copyWith(fontSize: 13.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVaccine = entry.isVaccination;

    return AppCard(
      onTap: () => _showDetailSheet(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVaccine
                  ? Icons.vaccines_outlined
                  : Icons.monitor_weight_outlined,
              size: 24,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isVaccine ? 'Imunisasi / Vitamin' : 'Pemeriksaan gizi',
                      style: AppText.caption.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Lihat detail',
                      style: AppText.caption.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(entry.childName, style: AppText.subtitle),
                Text(dateText, style: AppText.caption),
                const SizedBox(height: AppSpace.sm),
                Text(
                  entry.detail,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.notes_rounded,
                          size: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.note,
                          style: AppText.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntry {
  final bool isVaccination;
  final Object? childId;
  final String childName;
  final String date;
  final String detail;
  final String note;

  const _HistoryEntry({
    required this.isVaccination,
    this.childId,
    required this.childName,
    required this.date,
    required this.detail,
    required this.note,
  });
}