import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import '../models/anak.dart';
import '../models/pemeriksaan.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import 'artikel_page.dart';
import 'data_anak_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'profil_page.dart';

class PerkembanganPage extends StatefulWidget {
  const PerkembanganPage({super.key});

  @override
  State<PerkembanganPage> createState() => _PerkembanganPageState();
}

class _PerkembanganPageState extends State<PerkembanganPage> {
  List<Anak> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];

  Object? selectedAnakId;
  String selectedMetric = 'BB/U';

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
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
      final childrenRows = await supabase
          .from('anak')
          .select()
          .eq('user_id', user.id)
          .order('nama');

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

        if (selectedAnakId == null ||
            !childList.any((child) => child.id == selectedAnakId)) {
          selectedAnakId = childList.isEmpty ? null : childList.first.id;
        }

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadError = 'Gagal memuat data perkembangan: $error';
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

  String formatTanggal(String tanggal) {
    final date = DateTime.tryParse(tanggal);

    if (date == null) return tanggal;

    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  void _onNavigationTap(BuildContext context, int index) {
    final page = switch (index) {
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

  @override
  Widget build(BuildContext context) {
    final anak = anakTerpilih;
    final riwayat = pemeriksaanAnak;
    final terbaru = pemeriksaanTerakhir;

    final nilaiGrafik = riwayat.map((record) {
      return selectedMetric == 'BB/U' ? record.beratBadan : record.tinggiBadan;
    }).toList();

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          title: const Text('Grafik Tumbuh'),
          actions: [
            IconButton(
              tooltip: 'Muat ulang data',
              onPressed: isLoading ? null : loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(
          anak: anak,
          riwayat: riwayat,
          terbaru: terbaru,
          nilaiGrafik: nilaiGrafik,
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 0,
          onTap: (index) => _onNavigationTap(context, index),
        ),
      ),
    );
  }

  Widget _buildBody({
    required Anak? anak,
    required List<Pemeriksaan> riwayat,
    required Pemeriksaan? terbaru,
    required List<double> nilaiGrafik,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loadData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (dataAnak.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada data anak. Tambahkan data anak terlebih dahulu.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Perkembangan Anak',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pantau perubahan pertumbuhan si kecil dari waktu ke waktu.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // PILIH ANAK
          DropdownButtonFormField<Object>(
            initialValue: selectedAnakId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Pilih Anak',
              prefixIcon: const Icon(Icons.child_care, color: Colors.green),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: dataAnak.map((item) {
              return DropdownMenuItem<Object>(
                value: item.id!,
                child: Text(item.nama),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedAnakId = value;
              });
            },
          ),

          const SizedBox(height: 18),

          if (anak != null)
            HeroCard(
              color: AppColors.parent,
              child: Row(
                children: [
                  const ChildAvatar(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anak.nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${anak.jenisKelamin} • ${anak.tanggalLahir}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${riwayat.length} pemeriksaan tercatat',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 22),

          // RINGKASAN PEMERIKSAAN
          const Text(
            'Ringkasan Pertumbuhan',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            terbaru == null
                ? 'Belum ada data pengukuran.'
                : 'Pemeriksaan terakhir: ${formatTanggal(terbaru.tanggal)}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 14),

          if (terbaru == null)
            _emptyCard(
              Icons.monitor_weight_outlined,
              'Belum ada hasil pemeriksaan',
              'Hasil pengukuran akan tampil setelah kader menyimpan pemeriksaan.',
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Berat Badan',
                    value: '${terbaru.beratBadan.toStringAsFixed(1)} kg',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.height,
                    title: 'Tinggi Badan',
                    value: '${terbaru.tinggiBadan.toStringAsFixed(1)} cm',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _trendCard(
                    title: 'Perubahan Berat',
                    value: formatPerubahan(perubahanBerat, 'kg'),
                    icon: Icons.monitor_weight_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _trendCard(
                    title: 'Perubahan Tinggi',
                    value: formatPerubahan(perubahanTinggi, 'cm'),
                    icon: Icons.height,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Perubahan dihitung dari dua pemeriksaan terakhir. '
              'Kenaikan atau penurunan angka tidak otomatis menentukan '
              'status gizi anak.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],

          const SizedBox(height: 26),

          // GRAFIK
          const Text(
            'Grafik Pertumbuhan',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lihat perubahan hasil pengukuran berdasarkan riwayat pemeriksaan.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 14),

          ChipSelector(
            options: const ['BB/U', 'TB/U', 'KMS'],
            selected: selectedMetric,
            roleColor: AppColors.parent,
            softColor: AppColors.parentSoft,
            onSelected: (value) {
              setState(() {
                selectedMetric = value;
              });
            },
          ),
          const SizedBox(height: 14),

          if (selectedMetric == 'KMS')
            _emptyCard(
              Icons.menu_book_outlined,
              'Data KMS belum tersedia',
              'Standar KMS belum terhubung dengan data pertumbuhan aplikasi.',
            )
          else if (riwayat.isEmpty)
            _emptyCard(
              Icons.show_chart,
              'Belum ada grafik',
              'Grafik akan tampil setelah ada hasil pemeriksaan yang tersimpan.',
            )
          else
            _buildChart(riwayat, nilaiGrafik),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.parentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.parent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Grafik ini menampilkan riwayat pengukuran anak, '
                    'bukan kurva standar pertumbuhan WHO. '
                    'Penilaian status pertumbuhan memerlukan standar '
                    'yang sesuai usia dan jenis kelamin.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // RIWAYAT
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat Pertumbuhan',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${riwayat.length} data',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (riwayat.isEmpty)
            _emptyCard(
              Icons.history,
              'Belum ada riwayat',
              'Riwayat akan muncul setelah pemeriksaan disimpan.',
            )
          else
            ...riwayat.reversed.map((pemeriksaan) {
              return _historyCard(pemeriksaan);
            }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChart(List<Pemeriksaan> riwayat, List<double> values) {
    final satuan = selectedMetric == 'BB/U' ? 'kg' : 'cm';
    final judul = selectedMetric == 'BB/U' ? 'Berat Badan' : 'Tinggi Badan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Satuan: $satuan • ${values.length} pengukuran',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _GrowthChartPainter(
                values: values,
                lineColor: AppColors.parent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (riwayat.length >= 2)
            Text(
              'Terakhir: ${values.last.toStringAsFixed(1)} $satuan '
              '(${formatTanggal(riwayat.last.tanggal)})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            )
          else
            Text(
              'Pengukuran pertama: ${values.first.toStringAsFixed(1)} $satuan',
              style: const TextStyle(fontSize: 13),
            ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.circle, size: 9, color: AppColors.parent),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Titik menunjukkan hasil pengukuran yang tercatat.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Pemeriksaan pemeriksaan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.show_chart, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTanggal(pemeriksaan.tanggal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 7),
                Text('Berat: ${pemeriksaan.beratBadan.toStringAsFixed(1)} kg'),
                const SizedBox(height: 3),
                Text(
                  'Tinggi: ${pemeriksaan.tinggiBadan.toStringAsFixed(1)} cm',
                ),
                if (pemeriksaan.catatan.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    pemeriksaan.catatan,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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

class _GrowthChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  const _GrowthChartPainter({required this.values, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;

    const left = 35.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 18.0;

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
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    final textStyle = const TextStyle(color: Colors.grey, fontSize: 10);

    for (var row = 0; row <= 3; row++) {
      final y = chart.top + chart.height * row / 3;

      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);

      final value = upper - totalRange * row / 3;
      final text = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(1), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: left - 5);

      text.paint(canvas, Offset(0, y - text.height / 2));
    }

    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (values.length - 1);

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

    for (var i = 0; i < points.length; i++) {
      final point = points[i];

      canvas.drawCircle(point, 5, Paint()..color = Colors.white);

      canvas.drawCircle(point, 3.5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        !listEquals(oldDelegate.values, values);
  }
}
