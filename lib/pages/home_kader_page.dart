import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_theme.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'jadwal_page.dart';
import 'pemeriksaan_page.dart';

typedef KaderRecord = Map<String, dynamic>;

class HomeKaderPage extends StatefulWidget {
  const HomeKaderPage({super.key});

  @override
  State<HomeKaderPage> createState() => _HomeKaderPageState();
}

class _HomeKaderPageState extends State<HomeKaderPage> {
  late Future<int> _childCount;

  int _ditimbangCount = 0;
  int _imunisasiCount = 0;
  KaderRecord _nextJadwal = {};
  bool _hasNextJadwal = false;
  List<KaderRecord> _recentPemeriksaan = [];
  Map<String, String> _childNames = {};

  @override
  void initState() {
    super.initState();
    _childCount = _loadChildCount();
    _loadAdditionalDashboardData();
  }

  Future<int> _loadChildCount() async {
    final rows = await Supabase.instance.client.from('anak').select('id');
    return rows.length;
  }

  Future<void> _loadAdditionalDashboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Data anak untuk lookup nama
      final anakList = await supabase.from('anak').select('id, nama');
      final Map<String, String> names = {};
      for (final a in anakList) {
        final id = a['id']?.toString() ?? '';
        names[id] = a['nama']?.toString() ?? '-';
      }

      // 2. Pemeriksaan terbaru & hitung pemeriksaan
      final pRows = await supabase
          .from('pemeriksaan')
          .select('id, anak_id, tanggal, berat_badan, tinggi_badan')
          .order('tanggal', ascending: false)
          .limit(5);

      final pAll = await supabase.from('pemeriksaan').select('id');

      // 3. Imunisasi count
      final iAll = await supabase.from('imunisasi').select('id');

      // 4. Jadwal berikutnya
      final jRows = await supabase
          .from('jadwal')
          .select()
          .order('tanggal')
          .limit(1);

      if (!mounted) return;

      setState(() {
        _childNames = names;
        _recentPemeriksaan = List<KaderRecord>.from(pRows);
        _ditimbangCount = pAll.length;
        _imunisasiCount = iAll.length;
        _hasNextJadwal = jRows.isNotEmpty;
        _nextJadwal = jRows.isNotEmpty ? jRows.first : {};
      });
    } catch (_) {
      // Data opsional tambahan tidak boleh memblokir aplikasi
    }
  }

  void _refreshChildCount() {
    if (mounted) {
      setState(() {
        _childCount = _loadChildCount();
      });
    }
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      _refreshChildCount();
      _loadAdditionalDashboardData();
    });
  }

  String _formatTanggal(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day} ${bulanSingkat(date.month)} ${date.year}';
  }

  String _formatTanggalSingkat(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day} ${bulanSingkat(date.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = displayNameFromUser(user, fallback: 'Kader');
    final now = DateTime.now();
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final nextJadwalDate = _hasNextJadwal
        ? _formatTanggalSingkat(_nextJadwal['tanggal']?.toString())
        : '-';
    final nextJadwalFullDate = _hasNextJadwal
        ? _formatTanggal(_nextJadwal['tanggal']?.toString())
        : 'Belum ada jadwal';
    final nextJadwalTime = _nextJadwal['waktu']?.toString() ?? '08:00 - 11:00';
    final nextJadwalLocation =
        _nextJadwal['lokasi']?.toString() ?? 'Balai RW / Posyandu';

    return KaderWebScaffold(
      activeIndex: 0,
      breadcrumb: 'Beranda / Beranda',
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 16 : 24,
          isMobile ? 16 : 24,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. Banner Sambutan Biru Navy Solid
            // =================================================================
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 28,
                vertical: isMobile ? 20 : 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang,',
                          style: AppText.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.headline.copyWith(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Posyandu Melati · Periode ${bulanLengkap(now.month)} ${now.year}',
                          style: AppText.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SiPosyanduLogoIcon(size: isMobile ? 44 : 52),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // =================================================================
            // 2. 4 Kartu Statistik (Tanpa GridView agar bebas overflow)
            // =================================================================
            FutureBuilder<int>(
              future: _childCount,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                final countString = snapshot.hasData ? '$count' : '...';

                final card1 = _buildStatCard(
                  icon: Icons.people_outline_rounded,
                  value: countString,
                  label: 'Anak terdaftar',
                );
                final card2 = _buildStatCard(
                  icon: Icons.assignment_outlined,
                  value: '$_ditimbangCount',
                  label: 'Ditimbang bulan ini',
                );
                final card3 = _buildStatCard(
                  icon: Icons.colorize_outlined,
                  value: '$_imunisasiCount',
                  label: 'Imunisasi bulan ini',
                );
                final card4 = _buildStatCard(
                  icon: Icons.calendar_today_outlined,
                  value: nextJadwalDate,
                  label: 'Jadwal berikutnya',
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 680) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: card1),
                              const SizedBox(width: 12),
                              Expanded(child: card2),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: card3),
                              const SizedBox(width: 12),
                              Expanded(child: card4),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 16),
                        Expanded(child: card2),
                        const SizedBox(width: 16),
                        Expanded(child: card3),
                        const SizedBox(width: 16),
                        Expanded(child: card4),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // =================================================================
            // 3. Pemeriksaan Terbaru & Jadwal Terdekat
            // =================================================================
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 750;
                final isCompactList = constraints.maxWidth < 560;

                final tableSection = Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pemeriksaan terbaru',
                              style: AppText.subtitle.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _open(
                                context,
                                const PemeriksaanPage(openFormOnStart: false),
                              );
                            },
                            child: const Text('Lihat semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_recentPemeriksaan.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Belum ada data pemeriksaan terbaru.',
                              style: AppText.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                        )
                      else if (isCompactList)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentPemeriksaan.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 16,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final item = _recentPemeriksaan[index];
                            final anakId = item['anak_id']?.toString() ?? '';
                            final anakNama =
                                _childNames[anakId] ?? 'Tidak diketahui';
                            final tgl = _formatTanggal(
                              item['tanggal']?.toString(),
                            );
                            final bb = item['berat_badan'];

                            return Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: AppText.caption.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        anakNama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Penimbangan${bb != null ? " ($bb kg)" : ""} · $tgl',
                                        style: AppText.caption.copyWith(
                                          color: AppColors.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const StatusGiziBadge(status: 'Gizi baik'),
                              ],
                            );
                          },
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  'No',
                                  style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Anak',
                                  style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Jenis',
                                  style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Tanggal',
                                  style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentPemeriksaan.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final item = _recentPemeriksaan[index];
                            final anakId = item['anak_id']?.toString() ?? '';
                            final anakNama =
                                _childNames[anakId] ?? 'Tidak diketahui';
                            final tgl = _formatTanggal(
                              item['tanggal']?.toString(),
                            );

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      '${index + 1}',
                                      style: AppText.caption.copyWith(
                                        color: AppColors.secondaryText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      anakNama,
                                      style: AppText.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Penimbangan',
                                      style: AppText.caption.copyWith(
                                        color: AppColors.secondaryText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      tgl,
                                      style: AppText.caption.copyWith(
                                        color: AppColors.secondaryText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: StatusGiziBadge(
                                        status: 'Gizi baik',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );

                final scheduleSection = Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal terdekat',
                        style: AppText.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Posyandu Melati',
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$nextJadwalFullDate · $nextJadwalTime · $nextJadwalLocation',
                        style: AppText.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          _open(context, const JadwalPage(isKader: true));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(color: AppColors.navy),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(120, 38),
                        ),
                        child: const Text('Kelola jadwal'),
                      ),
                    ],
                  ),
                );

                if (isStacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      tableSection,
                      const SizedBox(height: 16),
                      scheduleSection,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 65, child: tableSection),
                    const SizedBox(width: 16),
                    Expanded(flex: 35, child: scheduleSection),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.navy, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.headline.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}