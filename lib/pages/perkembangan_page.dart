import 'package:flutter/material.dart';
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
            .inFilter('anak_id', childIds)
            .order('tanggal', ascending: true);
      }
      final examinations = examinationRows
          .map((row) => Pemeriksaan.fromMap(row))
          .toList();
      if (!mounted) return;
      setState(() {
        dataAnak = childList;
        dataPemeriksaan = examinations;
        selectedAnakId ??= childList.isEmpty ? null : childList.first.id;
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
    if (selectedAnakId == null) {
      return [];
    }

    return dataPemeriksaan
        .where((item) => item.anakId == selectedAnakId)
        .toList();
  }

  Anak? get anakTerpilih {
    if (selectedAnakId == null) {
      return null;
    }

    for (final anak in dataAnak) {
      if (anak.id == selectedAnakId) {
        return anak;
      }
    }

    return null;
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

    Pemeriksaan? pemeriksaanTerakhir;

    if (riwayat.isNotEmpty) {
      pemeriksaanTerakhir = riwayat.last;
    }

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Grafik Tumbuh')),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(loadError!, textAlign: TextAlign.center),
              ),
            )
          : dataAnak.isEmpty
          ? const Center(
              child: Text(
                'Belum ada data anak.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perkembangan Anak',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Pantau pertumbuhan berdasarkan hasil pemeriksaan.',
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // PILIH ANAK
                    DropdownButtonFormField<Object>(
                      initialValue: selectedAnakId,
                      decoration: InputDecoration(
                        labelText: 'Pilih Anak',
                        prefixIcon: const Icon(
                          Icons.child_care,
                          color: Colors.green,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: dataAnak.map((anak) {
                        return DropdownMenuItem<Object>(
                          value: anak.id!,
                          child: Text(anak.nama),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAnakId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // DATA ANAK
                    if (anak != null)
                      HeroCard(
                        color: AppColors.parent,
                        child: Row(
                          children: [
                            const ChildAvatar(size: 52),
                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    anak.nama,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '${anak.jenisKelamin} • ${anak.tanggalLahir}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    ChipSelector(
                      options: const ['BB/U', 'TB/U', 'KMS'],
                      selected: selectedMetric,
                      roleColor: AppColors.parent,
                      softColor: AppColors.parentSoft,
                      onSelected: (value) =>
                          setState(() => selectedMetric = value),
                    ),
                    const SizedBox(height: 14),
                    if (selectedMetric == 'KMS')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.parentSoft,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Text(
                          'Data KMS belum tersedia.',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      )
                    else if (riwayat.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.parentSoft,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Text(
                          'Belum ada hasil pemeriksaan untuk ditampilkan.',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        decoration: BoxDecoration(
                          color: AppColors.parentSoft,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 170,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _GrowthChartPainter(
                                  values: riwayat
                                      .map(
                                        (record) => selectedMetric == 'BB/U'
                                            ? record.beratBadan
                                            : record.tinggiBadan,
                                      )
                                      .toList(),
                                  lineColor: AppColors.parent,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Waktu pemeriksaan  ·  '
                                '${selectedMetric == 'BB/U' ? 'Berat (kg)' : 'Tinggi (cm)'}',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _ChartLegend(
                          color: AppColors.parent,
                          label: 'Hasil pemeriksaan',
                        ),
                        _ChartLegend(
                          color: Color(0xFFFDE68A),
                          label: 'Jalur normal belum tersedia',
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.parentSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.parent,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Grafik memakai hasil pemeriksaan yang tersimpan. '
                              'Status gizi dan pita standar WHO/KMS belum '
                              'tersedia pada data aplikasi.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Text(
                      'Hasil Terakhir',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (pemeriksaanTerakhir == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 45,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Belum ada hasil pemeriksaan.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.monitor_weight_outlined,
                              title: 'Berat Badan',
                              value: '${pemeriksaanTerakhir.beratBadan} kg',
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.height,
                              title: 'Tinggi Badan',
                              value: '${pemeriksaanTerakhir.tinggiBadan} cm',
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 25),

                    const Text(
                      'Riwayat Pertumbuhan',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (riwayat.isEmpty)
                      const Text(
                        'Belum ada riwayat pertumbuhan.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) {
                          final pemeriksaan = riwayat[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2E5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.show_chart,
                                    color: Colors.green,
                                  ),
                                ),

                                const SizedBox(width: 15),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pemeriksaan.tanggal,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        'BB: ${pemeriksaan.beratBadan} kg • '
                                        'TB: ${pemeriksaan.tinggiBadan} cm',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),

                                      if (pemeriksaan.catatan.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            pemeriksaan.catatan,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: AppBottomNav(
        isKader: false,
        selectedIndex: 0,
        onTap: (index) => _onNavigationTap(context, index),
      ),
    ));
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green, size: 32),

          const SizedBox(height: 10),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _GrowthChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  const _GrowthChartPainter({
    required this.values,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;
    const left = 8.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 18.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFD1FAE5)
      ..strokeWidth = 1;
    for (var row = 0; row < 4; row++) {
      final y = chart.top + chart.height * row / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;
    final paddedRange = range == 0 ? 1.0 : range * 1.25;
    final lower = minValue - (paddedRange - range) / 2;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (values.length - 1);
      final y = chart.bottom -
          ((values[index] - lower) / paddedRange) * chart.height;
      points.add(Offset(x, y));
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3.5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(_GrowthChartPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.values != values;
}
