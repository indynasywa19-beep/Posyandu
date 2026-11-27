import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/child_picker.dart';
import '../widgets/design_tokens.dart';
import 'data_anak_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'perkembangan_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';
import 'artikel_page.dart';

typedef ChildRecord = Map<String, dynamic>;

class HomeOrtuPage extends StatefulWidget {
  const HomeOrtuPage({super.key});

  @override
  State<HomeOrtuPage> createState() => _HomeOrtuPageState();
}

class _HomeOrtuPageState extends State<HomeOrtuPage> {
  List<ChildRecord> _childrenList = [];
  ChildRecord? _selectedChild;
  String _lastImmunization = '-';
  String _nextPosyanduDate = '-';
  String _nutritionStatus = '-';
  bool _isLoading = true;

  RealtimeChannel? _childrenChannel;

  @override
  void initState() {
    super.initState();
    _loadParentData();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _childrenChannel = Supabase.instance.client
          .channel('dashboard-ortu-anak')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'anak',
            callback: (_) => _loadParentData(),
          )
          .subscribe();
    }
  }

  Future<void> _loadParentData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final supabase = Supabase.instance.client;
    List<ChildRecord> list = _childrenList;
    ChildRecord? currentSelected = _selectedChild;

    // 1. Data anak milik orang tua yang sedang login (terpisah agar pasti tampil)
    try {
      final rows = await supabase
          .from('anak')
          .select()
          .eq('user_id', user.id)
          .order('nama');

      list = List<ChildRecord>.from(rows);

      if (currentSelected == null && list.isNotEmpty) {
        currentSelected = list.first;
      } else if (currentSelected != null &&
          !list.any((c) => c['id'] == currentSelected!['id'])) {
        currentSelected = list.isNotEmpty ? list.first : null;
      }
    } catch (e) {
      debugPrint('Error load anak ortu: $e');
    }

    // 2. Jadwal posyandu mendatang terdekat
    String nextDate = 'Belum ada';
    try {
      final todayIso = DateTime.now().toIso8601String().substring(0, 10);
      final jRows = await supabase
          .from('jadwal')
          .select('tanggal')
          .gte('tanggal', todayIso)
          .order('tanggal', ascending: true)
          .limit(1);

      if (jRows.isNotEmpty) {
        final raw = jRows.first['tanggal']?.toString();
        final dt = DateTime.tryParse(raw ?? '');
        if (dt != null) {
          nextDate = '${dt.day} ${bulanSingkat(dt.month)}';
        }
      }
    } catch (e) {
      debugPrint('Error load jadwal ortu: $e');
    }

    // 3. Imunisasi & pemeriksaan terakhir anak terpilih
    String lastIm = 'Belum ada';
    String nutrition = 'Belum ada';

    if (currentSelected != null) {
      final childId = currentSelected['id'];

      try {
        final imRows = await supabase
            .from('imunisasi')
            .select()
            .eq('anak_id', childId)
            .order('tanggal', ascending: false)
            .limit(1);

        if (imRows.isNotEmpty) {
          lastIm = imRows.first['nama_vaksin']?.toString() ?? 'Tercatat';
        }
      } catch (e) {
        debugPrint('Error load imunisasi ortu: $e');
      }

      try {
        final examRows = await supabase
            .from('pemeriksaan')
            .select()
            .eq('anak_id', childId)
            .order('tanggal', ascending: false)
            .limit(1);

        if (examRows.isNotEmpty) {
          final row = examRows.first;
          final statusGizi = row['status_gizi']?.toString() ?? '';
          final bb = row['berat_badan'];
          if (statusGizi.isNotEmpty) {
            nutrition = statusGizi;
          } else if (bb != null) {
            nutrition = '$bb kg';
          }
        }
      } catch (e) {
        debugPrint('Error load pemeriksaan ortu: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _childrenList = list;
      _selectedChild = currentSelected;
      _nextPosyanduDate = nextDate;
      _lastImmunization = lastIm;
      _nutritionStatus = nutrition;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    try {
      await _loadParentData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(
              error,
              fallback:
                  'Data anak belum bisa dimuat. Tarik layar ke bawah untuk mencoba lagi.',
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_childrenChannel != null) {
      Supabase.instance.client.removeChannel(_childrenChannel!);
    }
    super.dispose();
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      _loadParentData();
    });
  }

  void _onNavigationTap(int index) {
    if (index == 0) return;

    final Widget? page = switch (index) {
      1 => const DataAnakPage(),
      2 => const JadwalPage(),
      3 => const RiwayatPage(),
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

  Future<void> _openChildFeature(BuildContext context, Widget page) async {
    if (_childrenList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan data anak terlebih dahulu.')),
      );
      _open(context, const DataAnakPage());
      return;
    }

    _open(context, page);
  }

  Future<void> _pickChild() async {
    if (_childrenList.isEmpty) {
      _open(context, const DataAnakPage());
      return;
    }

    final selectedId = await showChildPicker(
      context,
      children: _childrenList,
      selectedId: _selectedChild?['id']?.toString(),
    );

    if (selectedId != null && mounted) {
      setState(() {
        _selectedChild = _childrenList.firstWhere(
          (c) => c['id'].toString() == selectedId,
          orElse: () => _childrenList.first,
        );
      });
      await _loadParentData();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk membuka SI-POSYANDU.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(
              error,
              fallback: 'Belum bisa keluar dari akun. Coba lagi.',
            ),
          ),
        ),
      );
    }
  }

  String _formatTanggalLahir(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day} ${bulanSingkat(date.month)} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final parentName = displayNameFromUser(user, fallback: 'Orang Tua');
    final now = DateTime.now();

    final hasChild = _selectedChild != null;
    final childName = _selectedChild?['nama']?.toString() ?? '-';
    final childNik = _selectedChild?['nik']?.toString() ?? '-';
    final childBirth = _formatTanggalLahir(
      _selectedChild?['tanggal_lahir']?.toString(),
    );
    final childGender =
        _selectedChild?['jenis_kelamin']?.toString() ?? '-';
    final childCountTotal = _childrenList.length;

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppColors.navy,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: SiPosyanduBrand(
                                  textColor: Colors.white,
                                  govColor: Colors.white70,
                                  iconSize: 34,
                                ),
                              ),
                              LogoutButton(
                                inverted: true,
                                onPressed: () => _logout(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selamat datang,',
                                      style: AppText.body.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      parentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.headline.copyWith(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const OrtuBadge(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 90,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : !hasChild
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Belum ada data anak terdaftar',
                                      style: AppText.title.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Daftarkan identitas si kecil di menu Data Anak untuk mulai memantau pertumbuhan dan imunisasi.',
                                      style: AppText.caption.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () => _open(
                                          context,
                                          const DataAnakPage(),
                                        ),
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Daftarkan Anak'),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Nama anak',
                                                style: AppText.caption.copyWith(
                                                  color:
                                                      AppColors.secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                childName,
                                                style: AppText.title.copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Tanggal lahir',
                                                style: AppText.caption.copyWith(
                                                  color:
                                                      AppColors.secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                childBirth,
                                                style: AppText.title.copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'NIK',
                                                style: AppText.caption.copyWith(
                                                  color:
                                                      AppColors.secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                childNik,
                                                style: AppText.title.copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Jenis kelamin',
                                                style: AppText.caption.copyWith(
                                                  color:
                                                      AppColors.secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                childGender,
                                                style: AppText.title.copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    InkWell(
                                      onTap: _pickChild,
                                      borderRadius: BorderRadius.circular(4),
                                      child: Text(
                                        childCountTotal > 1
                                            ? '$childCountTotal anak terdaftar · Ganti anak'
                                            : '$childCountTotal anak terdaftar · Lihat daftar',
                                        style: AppText.caption.copyWith(
                                          color: AppColors.logoGreen,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem(
                                title: _nutritionStatus,
                                subtitle: 'Status gizi',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryItem(
                                title: _lastImmunization,
                                subtitle: 'Imunisasi\nterakhir',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryItem(
                                title: _nextPosyanduDate,
                                subtitle: 'Posyandu\nberikutnya',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const SiPosyanduLogoIcon(size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Layanan',
                              style: AppText.title.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Divider(
                                color: AppColors.divider,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildServiceCard(
  icon: Icons.article_outlined,
  title: 'Artikel & Berita Kesehatan',
  subtitle: 'Informasi tumbuh kembang, gizi & imunisasi',
  onTap: () => _open(context, const ArtikelPage()),
),
const SizedBox(height: 12),

_buildServiceCard(
  icon: Icons.person_outline_rounded,
  title: 'Data Anak',
  subtitle: 'Identitas anak terdaftar',
  onTap: () => _open(context, const DataAnakPage()),
),
const SizedBox(height: 12),

_buildServiceCard(
  icon: Icons.show_chart_rounded,
  title: 'KMS Digital',
  subtitle: 'Grafik pertumbuhan & status gizi',
  onTap: () => _openChildFeature(
    context,
    PerkembanganPage(anakId: _selectedChild?['id']),
  ),
),
const SizedBox(height: 12),

_buildServiceCard(
  icon: Icons.calendar_month_outlined,
  title: 'Jadwal Posyandu',
  subtitle: 'Agenda dari Kader (hanya lihat)',
  onTap: () => _open(context, const JadwalPage()),
),
const SizedBox(height: 12),

_buildServiceCard(
  icon: Icons.access_time_rounded,
  title: 'Riwayat Anak',
  subtitle: 'Penimbangan & imunisasi',
  onTap: () =>
      _openChildFeature(context, const RiwayatPage()),
),

const SizedBox(height: 36),

Center(
  child: Text(
    '© ${now.year} SI-POSYANDU · Kebijakan Privasi · v1.0',
    style: AppText.caption.copyWith(
      color: AppColors.mutedText,
      fontSize: 12,
    ),
  ),
),
const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 0,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: AppText.title.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppText.caption.copyWith(
              color: AppColors.secondaryText,
              fontSize: 11.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.navy, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.title.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.caption.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}