import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anak.dart';
import '../models/pemeriksaan.dart';
import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/child_picker.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'artikel_page.dart';
import 'data_anak_page.dart';
import 'home_kader_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'pemeriksaan_page.dart' hide Pemeriksaan;
import 'profil_page.dart';

class PerkembanganPage extends StatefulWidget {
  final bool isKader;
  final Object? anakId;

  const PerkembanganPage({super.key, this.isKader = false, this.anakId});

  @override
  State<PerkembanganPage> createState() => _PerkembanganPageState();
}

class _PerkembanganPageState extends State<PerkembanganPage> {
  static const _metricWeight = 'Berat badan';
  static const _metricHeight = 'Tinggi badan';
  static const _metricKms = 'KMS';

  List<Anak> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];

  Object? selectedAnakId;
  String selectedMetric = _metricWeight;

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
  Future<void> loadData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (!widget.isKader && user == null) {
      if (!mounted) return;

      setState(() {
        loadError = 'Sesi login tidak ditemukan. Silakan masuk kembali.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final List<Map<String, dynamic>> childrenRows;

      if (widget.isKader) {
        childrenRows = await supabase.from('anak').select().order('nama');
      } else {
        childrenRows = await supabase
            .from('anak')
            .select()
            .eq('user_id', user!.id)
            .order('nama');
      }

      final childList = childrenRows.map((row) => Anak.fromMap(row)).toList();

      final childIds = childList
          .map((child) => child.id)
          .whereType<Object>()
          .toList();

      final List<Map<String, dynamic>> examinationRows;

      if (childIds.isEmpty) {
        examinationRows = [];
      } else {
        examinationRows = await supabase
            .from('pemeriksaan')
            .select()
            .inFilter('anak_id', childIds);
      }

      final examinations = examinationRows
          .map((row) => Pemeriksaan.fromMap(row))
          .toList();

      // Urutkan berdasarkan tanggal pemeriksaan.
      examinations.sort((a, b) {
        final dateA = DateTime.tryParse(a.tanggal);
        final dateB = DateTime.tryParse(b.tanggal);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return -1;
        if (dateB == null) return 1;

        return dateA.compareTo(dateB);
      });

      if (!mounted) return;

      setState(() {
        dataAnak = childList;
        dataPemeriksaan = examinations;

        if (widget.anakId != null &&
            childList.any(
              (child) => child.id.toString() == widget.anakId.toString(),
            )) {
          selectedAnakId = childList
              .firstWhere(
                (child) => child.id.toString() == widget.anakId.toString(),
              )
              .id;
        } else if (selectedAnakId == null ||
            !childList.any((child) => child.id == selectedAnakId)) {
          selectedAnakId = childList.isEmpty ? null : childList.first.id;
        }

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadError = friendlyError(
          error,
          fallback: 'Data perkembangan belum bisa dimuat. Coba lagi sebentar lagi.',
        );
        isLoading = false;
      });
    }
  }

  List<Pemeriksaan> get pemeriksaanAnak {
    if (selectedAnakId == null) return [];

    return dataPemeriksaan
        .where((item) => item.anakId == selectedAnakId)
        .toList();
  }

  Anak? get anakTerpilih {
    for (final anak in dataAnak) {
      if (anak.id == selectedAnakId) return anak;
    }

    return null;
  }

  Pemeriksaan? get pemeriksaanTerakhir {
    final riwayat = pemeriksaanAnak;

    return riwayat.isEmpty ? null : riwayat.last;
  }

  Pemeriksaan? get pemeriksaanSebelumnya {
    final riwayat = pemeriksaanAnak;

    return riwayat.length < 2 ? null : riwayat[riwayat.length - 2];
  }

  double? get perubahanBerat {
    final terbaru = pemeriksaanTerakhir;
    final sebelumnya = pemeriksaanSebelumnya;

    if (terbaru == null || sebelumnya == null) return null;

    return terbaru.beratBadan - sebelumnya.beratBadan;
  }

  double? get perubahanTinggi {
    final terbaru = pemeriksaanTerakhir;
    final sebelumnya = pemeriksaanSebelumnya;

    if (terbaru == null || sebelumnya == null) return null;

    return terbaru.tinggiBadan - sebelumnya.tinggiBadan;
  }

  String formatPerubahan(double? nilai, String satuan) {
    if (nilai == null) return 'Belum ada pembanding';

    if (nilai > 0) {
      return 'Naik ${nilai.toStringAsFixed(1)} $satuan';
    }

    if (nilai < 0) {
      return 'Turun ${nilai.abs().toStringAsFixed(1)} $satuan';
    }

    return 'Tidak berubah';
  }

  /// Ikon arah perubahan. Sengaja netral (tidak hijau/merah): naik atau turun
  /// tidak otomatis berarti baik atau buruk.
  IconData _arahPerubahan(double? nilai) {
    if (nilai == null) return Icons.horizontal_rule_rounded;
    if (nilai > 0) return Icons.trending_up_rounded;
    if (nilai < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  /// Contoh: "9 Nov 2026".
  String formatTanggal(String tanggal) {
    final date = DateTime.tryParse(tanggal);

    if (date == null) return tanggal;

    return '${date.day} ${bulanSingkat(date.month)} ${date.year}';
  }

  String _tanggalLengkap(String tanggal) {
    final date = DateTime.tryParse(tanggal);

    return date == null ? tanggal : tanggalLengkap(date);
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI
  // ---------------------------------------------------------------------------
  void _onParentNavigationTap(BuildContext context, int index) {
    final Widget? page = switch (index) {
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

  void _onKaderNavigationTap(BuildContext context, int index) {
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

  Future<void> _pickChild() async {
    final id = await showChildPicker(
      context,
      children: dataAnak
          .map((a) => {'id': a.id, 'nama': a.nama, 'nik': a.nik})
          .toList(),
      selectedId: selectedAnakId?.toString(),
    );

    if (id == null || !mounted) return;

    for (final a in dataAnak) {
      if (a.id.toString() == id) {
        setState(() => selectedAnakId = a.id);
        break;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isKader = widget.isKader;

    return Theme(
      data: isKader ? AppTheme.kader : AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isKader ? 'Detail & Monitoring Anak' : 'Detail & Grafik Anak',
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang data',
              onPressed: isLoading ? null : loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButtonLocation: isKader
            ? FloatingActionButtonLocation.centerDocked
            : null,
        floatingActionButton: isKader
            ? KaderCenterFab(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PemeriksaanPage(openFormOnStart: true),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: isKader
            ? KaderBottomAppBar(
                selectedIndex: 1,
                onTabSelected: (index) => _onKaderNavigationTap(context, index),
              )
            : AppBottomNav(
                isKader: false,
                selectedIndex: 1,
                onTap: (index) => _onParentNavigationTap(context, index),
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const LoadingState(message: 'Memuat data perkembangan');
    }

    if (loadError != null) {
      return ErrorState(
        title: 'Data perkembangan belum bisa dimuat',
        message: loadError!,
        onRetry: loadData,
      );
    }

    if (dataAnak.isEmpty) {
      return const EmptyState(
        icon: Icons.child_care_rounded,
        title: 'Belum ada data anak',
        message: 'Tambahkan data anak terlebih dahulu di menu Anak.',
      );
    }

    final anak = anakTerpilih;
    final riwayat = pemeriksaanAnak;
    final riwayatTerbaru = riwayat.reversed.toList();
    final terbaru = pemeriksaanTerakhir;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.sm,
          AppSpace.page,
          AppSpace.xl + AppSpace.lg,
        ),
        children: [
          // Pilih anak (hanya bila ada lebih dari satu)
          if (dataAnak.length > 1 && anak != null) ...[
            Text('Anak', style: AppText.label),
            const SizedBox(height: 6),
            KaderChildSelectorTile(
              childName: anak.nama,
              subtitle: 'NIK: ${anak.nik.isEmpty ? '-' : anak.nik}',
              onSelectChild: _pickChild,
            ),
            const SizedBox(height: AppSpace.lg),
          ],

          if (anak != null) _buildIdentityCard(anak, riwayat.length),
          const SizedBox(height: AppSpace.xl),

          // RINGKASAN
          SectionHeader(
            title: 'Ringkasan pertumbuhan',
            subtitle: terbaru == null
                ? 'Belum ada data pengukuran.'
                : 'Pemeriksaan terakhir: ${_tanggalLengkap(terbaru.tanggal)}',
          ),
          const SizedBox(height: AppSpace.md),
          if (terbaru == null)
            const _InfoPanel(
              icon: Icons.monitor_weight_outlined,
              title: 'Belum ada hasil pemeriksaan',
              message:
                  'Hasil pengukuran akan tampil setelah kader menyimpan pemeriksaan.',
            )
          else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Berat badan',
                      value: '${terbaru.beratBadan.toStringAsFixed(1)} kg',
                      changeIcon: _arahPerubahan(perubahanBerat),
                      changeText: formatPerubahan(perubahanBerat, 'kg'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.height_rounded,
                      title: 'Tinggi badan',
                      value: '${terbaru.tinggiBadan.toStringAsFixed(1)} cm',
                      changeIcon: _arahPerubahan(perubahanTinggi),
                      changeText: formatPerubahan(perubahanTinggi, 'cm'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Perubahan dihitung dari dua pemeriksaan terakhir. '
              'Kenaikan atau penurunan angka tidak otomatis menentukan '
              'status gizi anak.',
              style: AppText.caption,
            ),
          ],
          const SizedBox(height: AppSpace.xl),

          // GRAFIK
          const SectionHeader(
            title: 'Grafik pertumbuhan',
            subtitle:
                'Lihat perubahan hasil pengukuran berdasarkan riwayat pemeriksaan.',
          ),
          const SizedBox(height: AppSpace.md),
          ChoiceChipGroup(
            options: const [_metricWeight, _metricHeight, _metricKms],
            selected: selectedMetric,
            onChanged: (value) {
              // Selalu ada satu pilihan: mengetuk yang sedang terpilih
              // tidak membatalkannya.
              if (value.isNotEmpty) setState(() => selectedMetric = value);
            },
          ),
          const SizedBox(height: AppSpace.md),
          if (selectedMetric == _metricKms)
            const _InfoPanel(
              icon: Icons.menu_book_outlined,
              title: 'Data KMS belum tersedia',
              message:
                  'Standar KMS belum terhubung dengan data pertumbuhan aplikasi.',
            )
          else if (riwayat.isEmpty)
            const _InfoPanel(
              icon: Icons.show_chart_rounded,
              title: 'Belum ada grafik',
              message:
                  'Grafik akan tampil setelah ada hasil pemeriksaan yang tersimpan.',
            )
          else
            _buildChart(riwayat),
          const SizedBox(height: AppSpace.md),
          const InlineMessage(
            status: AppStatus.info,
            message:
                'Grafik ini menampilkan riwayat pengukuran anak, '
                'bukan kurva standar pertumbuhan WHO. '
                'Penilaian status pertumbuhan memerlukan standar '
                'yang sesuai usia dan jenis kelamin.',
          ),
          const SizedBox(height: AppSpace.xl),

          // RIWAYAT
          SectionHeader(
            title: 'Riwayat pertumbuhan',
            subtitle: '${riwayat.length} data',
          ),
          const SizedBox(height: AppSpace.md),
          if (riwayat.isEmpty)
            const _InfoPanel(
              icon: Icons.history_rounded,
              title: 'Belum ada riwayat',
              message: 'Riwayat akan muncul setelah pemeriksaan disimpan.',
            )
          else
            for (var i = 0; i < riwayatTerbaru.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.md),
              _HistoryCard(
                dateText: _tanggalLengkap(riwayatTerbaru[i].tanggal),
                weight: '${riwayatTerbaru[i].beratBadan.toStringAsFixed(1)} kg',
                height: '${riwayatTerbaru[i].tinggiBadan.toStringAsFixed(1)} cm',
                note: riwayatTerbaru[i].catatan.trim(),
              ),
            ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IDENTITAS (satu kartu, tidak lagi tiga kali)
  // ---------------------------------------------------------------------------
  Widget _buildIdentityCard(Anak anak, int jumlahPemeriksaan) {
    final gender = anak.jenisKelamin.trim().isEmpty ? '-' : anak.jenisKelamin;
    final birth = anak.tanggalLahir.trim().isEmpty
        ? '-'
        : _tanggalLengkap(anak.tanggalLahir);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: anak.nama, size: 52),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anak.nama, style: AppText.title),
                    const SizedBox(height: 2),
                    Text('$gender · Lahir $birth', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(),
          const SizedBox(height: AppSpace.md),
          _IdentityLine(
            icon: Icons.badge_outlined,
            label: 'NIK',
            value: anak.nik,
          ),
          const SizedBox(height: AppSpace.sm),
          _IdentityLine(
            icon: Icons.fact_check_outlined,
            label: 'Pemeriksaan',
            value: '$jumlahPemeriksaan tercatat',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GRAFIK
  // ---------------------------------------------------------------------------
  Widget _buildChart(List<Pemeriksaan> riwayat) {
    // Builder: agar Theme.of membaca tema peran (Kader/Orang Tua) di atas
    // Scaffold, bukan tema aplikasi di atas State ini.
    return Builder(builder: (context) => _chartCard(context, riwayat));
  }

  Widget _chartCard(BuildContext context, List<Pemeriksaan> riwayat) {
    final isWeight = selectedMetric == _metricWeight;
    final satuan = isWeight ? 'kg' : 'cm';
    final judul = isWeight ? 'Berat badan' : 'Tinggi badan';

    final values = riwayat
        .map((record) => isWeight ? record.beratBadan : record.tinggiBadan)
        .toList();
    final dates = riwayat.map((r) => DateTime.tryParse(r.tanggal)).toList();

    final lowest = values.reduce(math.min);
    final highest = values.reduce(math.max);
    final lastText = '${values.last.toStringAsFixed(1)} $satuan';

    final summary =
        'Grafik $judul. ${values.length} pengukuran. '
        'Terendah ${lowest.toStringAsFixed(1)} $satuan, '
        'tertinggi ${highest.toStringAsFixed(1)} $satuan. '
        'Terakhir $lastText pada ${_tanggalLengkap(riwayat.last.tanggal)}.';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: AppText.subtitle),
          const SizedBox(height: 2),
          Text(
            'Satuan: $satuan • ${values.length} pengukuran',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpace.lg),
          Semantics(
            label: summary,
            image: true,
            child: ExcludeSemantics(
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: CustomPaint(
                  painter: _GrowthChartPainter(
                    values: values,
                    dates: dates,
                    lineColor: Theme.of(context).colorScheme.primary,
                    gridColor: AppColors.divider,
                    labelStyle: AppText.caption,
                    firstLabel: formatTanggal(riwayat.first.tanggal),
                    lastLabel: formatTanggal(riwayat.last.tanggal),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          if (riwayat.length >= 2)
            Text(
              'Terakhir: $lastText (${formatTanggal(riwayat.last.tanggal)})',
              style: AppText.label,
            )
          else
            Text(
              'Pengukuran pertama: ${values.first.toStringAsFixed(1)} $satuan',
              style: AppText.label,
            ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 9,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Titik menunjukkan hasil pengukuran yang tercatat. '
                  'Jarak antartitik mengikuti tanggal pemeriksaan.',
                  style: AppText.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// KOMPONEN HALAMAN
// =============================================================================
class _IdentityLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IdentityLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: AppSpace.sm),
        SizedBox(
          width: 104,
          child: Text(label, style: AppText.caption),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: AppText.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final IconData changeIcon;
  final String changeText;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.changeIcon,
    required this.changeText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: AppText.caption)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.title.copyWith(fontSize: 24)),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(changeIcon, size: 18, color: AppColors.secondaryText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  changeText,
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl - 2),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, size: 36, color: scheme.primary),
            const SizedBox(height: AppSpace.md),
            Text(title, style: AppText.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppText.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String dateText;
  final String weight;
  final String height;
  final String note;

  const _HistoryCard({
    required this.dateText,
    required this.weight,
    required this.height,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
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
            child: Icon(Icons.show_chart_rounded, color: scheme.primary),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateText, style: AppText.subtitle),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Berat $weight · Tinggi $height',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: AppText.body.copyWith(color: AppColors.secondaryText),
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

// =============================================================================
// GRAFIK
// =============================================================================
/// Menggambar hasil pengukuran terhadap waktu. TIDAK menggambar kurva standar
/// atau penilaian apa pun.
///
/// Posisi titik mengikuti tanggal bila semua tanggal valid dan tidak semuanya
/// sama. Bila tidak, titik dibagi rata.
class _GrowthChartPainter extends CustomPainter {
  final List<double> values;
  final List<DateTime?> dates;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final String firstLabel;
  final String lastLabel;

  const _GrowthChartPainter({
    required this.values,
    required this.dates,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
    required this.firstLabel,
    required this.lastLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;

    const left = 44.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 26.0;

    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;
    final padding = range == 0 ? 1.0 : range * 0.25;

    final lower = minValue - padding;
    final upper = maxValue + padding;
    final totalRange = upper - lower;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Garis bantu dan angka sumbu tegak
    for (var row = 0; row <= 3; row++) {
      final y = chart.top + chart.height * row / 3;

      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);

      final value = upper - totalRange * row / 3;

      final text = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(1), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: left - 6);

      text.paint(canvas, Offset(left - 6 - text.width, y - text.height / 2));
    }

    // Posisi mendatar: menurut tanggal bila memungkinkan.
    final parsed = dates.whereType<DateTime>().toList();
    final byDate =
        parsed.length == dates.length &&
        parsed.length > 1 &&
        parsed.last.difference(parsed.first).inDays > 0;

    double fraction(int index) {
      if (values.length == 1) return 0.5;

      if (byDate) {
        final total = parsed.last.difference(parsed.first).inMilliseconds;
        final elapsed = parsed[index].difference(parsed.first).inMilliseconds;
        return elapsed / total;
      }

      return index / (values.length - 1);
    }

    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = chart.left + chart.width * fraction(index);
      final y =
          chart.bottom - ((values[index] - lower) / totalRange) * chart.height;

      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);

      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final point in points) {
      canvas.drawCircle(point, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
    }

    // Label tanggal pertama dan terakhir di sumbu mendatar
    final labelY = chart.bottom + 6;

    final first = TextPainter(
      text: TextSpan(text: firstLabel, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    if (values.length == 1) {
      first.paint(canvas, Offset(chart.center.dx - first.width / 2, labelY));
    } else {
      first.paint(canvas, Offset(chart.left, labelY));

      final last = TextPainter(
        text: TextSpan(text: lastLabel, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Hindari tumpang tindih bila ruangnya sempit.
      if (chart.left + first.width + 8 < chart.right - last.width) {
        last.paint(canvas, Offset(chart.right - last.width, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.firstLabel != firstLabel ||
        oldDelegate.lastLabel != lastLabel ||
        !listEquals(oldDelegate.values, values) ||
        !listEquals(oldDelegate.dates, dates);
  }
}
