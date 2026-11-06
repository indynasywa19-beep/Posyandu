import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'artikel_page.dart';
import 'data_anak_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'perkembangan_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

class HomeOrtuPage extends StatefulWidget {
  const HomeOrtuPage({super.key});

  @override
  State<HomeOrtuPage> createState() => _HomeOrtuPageState();
}

class _HomeOrtuPageState extends State<HomeOrtuPage> {
  // =========================================================
  // WARNA KONSEP TERBARU
  // =========================================================
  static const Color primaryBlue = Color(0xFF1261A0);
  static const Color lavender = Color(0xFFA99BCF);
  static const Color lavenderLight = Color(0xFFF4F1FA);
  static const Color navy = Color(0xFF123B5D);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE5E7EB);

  late Future<int> _childCount;

  RealtimeChannel? _childrenChannel;
  bool _realtimeErrorReported = false;

  @override
  void initState() {
    super.initState();

    _childCount = _loadChildCount();

    // Realtime hanya dijalankan ketika benar-benar login.
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      _childrenChannel = Supabase.instance.client
          .channel('dashboard-ortu-anak')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'anak',
            select: ['id'],
            callback: (_) => _refreshChildCount(),
          )
          .subscribe((status, error) {
            if ((status == RealtimeSubscribeStatus.channelError ||
                    status == RealtimeSubscribeStatus.timedOut) &&
                !_realtimeErrorReported &&
                mounted) {
              _realtimeErrorReported = true;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pembaruan data anak gagal: ${error ?? status}',
                  ),
                ),
              );
            }
          });
    }
  }

  // =========================================================
  // LOAD DATA ANAK
  // =========================================================
  Future<int> _loadChildCount() async {
    final user = Supabase.instance.client.auth.currentUser;

    // Saat menggunakan Preview Beranda tanpa login,
    // tampilkan kondisi "belum ada data anak".
    if (user == null) {
      return 0;
    }

    final rows = await Supabase.instance.client
        .from('anak')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  void _refreshChildCount() {
    if (!mounted) return;

    setState(() {
      _childCount = _loadChildCount();
    });
  }

  Future<void> _refresh() async {
    final nextCount = _loadChildCount();

    setState(() {
      _childCount = nextCount;
    });

    try {
      await nextCount;
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data anak: $error')));
    }
  }

  @override
  void dispose() {
    if (_childrenChannel != null) {
      Supabase.instance.client.removeChannel(_childrenChannel!);
    }

    super.dispose();
  }

  // =========================================================
  // NAVIGASI
  // =========================================================
  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      _refreshChildCount();
    });
  }

  Future<void> _openChildFeature(BuildContext context, Widget page) async {
    final user = Supabase.instance.client.auth.currentUser;

    // Saat preview, langsung buka halaman.
    if (user == null) {
      _open(context, page);
      return;
    }

    try {
      final children = await Supabase.instance.client
          .from('anak')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if (!context.mounted) return;

      if (children.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambahkan data anak terlebih dahulu.')),
        );

        _open(context, const DataAnakPage());

        return;
      }

      _open(context, page);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa data anak: $error')),
      );
    }
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================
  void _onNavigationTap(BuildContext context, int index) {
    final page = switch (index) {
      1 => const DataAnakPage(),
      2 => const JadwalPage(),
      3 => const ArtikelPage(),
      4 => const ProfilPage(),
      _ => null,
    };

    if (page != null) {
      _open(context, page);
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================
  Future<void> _logout(BuildContext context) async {
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar dari akun: $error')));
    }
  }

  // =========================================================
  // SERVICE CARD
  // =========================================================
  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: navy.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ARTICLE CARD
  // =========================================================
  Widget _buildArticleCard({
    required BuildContext context,
    required IconData icon,
    required String category,
    required String title,
    required String description,
    required String content,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () {
          // LANGSUNG BUKA DETAIL ARTIKEL
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailPage(
                title: title,
                content: content,
                icon: icon,
                iconColor: iconColor,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: navy.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ICON ARTIKEL
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: lavenderLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KATEGORI
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lavenderLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // JUDUL
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: navy,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // DESKRIPSI
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        color: secondaryText,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Row(
                      children: [
                        Text(
                          'Baca artikel',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: primaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================
  Widget _bottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                selected: true,
                onTap: () {},
              ),
              _bottomNavItem(
                icon: Icons.child_care_rounded,
                label: 'Anak',
                onTap: () {
                  _open(context, const DataAnakPage());
                },
              ),
              _bottomNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Jadwal',
                onTap: () {
                  _open(context, const JadwalPage());
                },
              ),
              _bottomNavItem(
                icon: Icons.article_outlined,
                label: 'Artikel',
                onTap: () {
                  _open(context, const ArtikelPage());
                },
              ),
              _bottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                onTap: () {
                  _open(context, const ProfilPage());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? primaryBlue : const Color(0xFF94A3B8),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? primaryBlue : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final rawName = user?.userMetadata?['display_name'];

    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Bunda';

    return Scaffold(
      backgroundColor: lavenderLight,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: lavenderLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 58,
        titleSpacing: 18,

        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: primaryBlue,
                size: 21,
              ),
            ),

            const SizedBox(width: 9),

            const Text(
              'SI-POSYANDU',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: navy,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belum ada notifikasi baru.')),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryBlue,
            ),
            icon: const Icon(Icons.notifications_none_rounded, size: 21),
          ),

          const SizedBox(width: 2),

          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: navy,
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),

          const SizedBox(width: 12),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // GREETING
                // =================================================
                const Text(
                  'Selamat pagi,',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),

                const SizedBox(height: 1),

                Text(
                  '$name 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Pantau kesehatan dan tumbuh kembang si kecil.',
                  style: TextStyle(fontSize: 11.5, color: secondaryText),
                ),

                const SizedBox(height: 14),

                // =================================================
                // DATA ANAK
                // =================================================
                FutureBuilder<int>(
                  future: _childCount,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: primaryBlue,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Data anak belum dapat dimuat.',
                                style: TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Container(
                        width: double.infinity,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: primaryBlue,
                          ),
                        ),
                      );
                    }

                    final count = snapshot.data!;

                    // =============================================
                    // BELUM ADA ANAK
                    // =============================================
                    if (count == 0) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: lavender.withOpacity(0.55)),
                          boxShadow: [
                            BoxShadow(
                              color: navy.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: lavenderLight,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.child_care_rounded,
                                color: primaryBlue,
                                size: 28,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Belum ada data si kecil',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: navy,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Tambahkan data anak untuk mulai memantau perkembangannya.',
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      height: 1.35,
                                      color: secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 7),

                            IconButton(
                              onPressed: () {
                                _open(context, const DataAnakPage());
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(38, 38),
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // =============================================
                    // ADA DATA ANAK
                    // =============================================
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: lavender.withOpacity(0.55)),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: lavenderLight,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.child_care_rounded,
                              color: primaryBlue,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Data anak terdaftar',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '$count anak',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: navy,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          OutlinedButton(
                            onPressed: () {
                              _open(context, const DataAnakPage());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryBlue,
                              side: const BorderSide(color: primaryBlue),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Lihat',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // =================================================
                // LAYANAN
                // =================================================
                const Text(
                  'Layanan keluarga',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Akses informasi kesehatan si kecil.',
                  style: TextStyle(fontSize: 11, color: secondaryText),
                ),

                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 2.05,
                  children: [
                    _serviceCard(
                      icon: Icons.child_care_rounded,
                      title: 'Data Anak',
                      subtitle: 'Identitas si kecil',
                      iconBackground: lavenderLight,
                      iconColor: primaryBlue,
                      onTap: () {
                        _open(context, const DataAnakPage());
                      },
                    ),

                    _serviceCard(
                      icon: Icons.show_chart_rounded,
                      title: 'Grafik Tumbuh',
                      subtitle: 'Pantau perkembangan',
                      iconBackground: lavenderLight,
                      iconColor: lavender,
                      onTap: () {
                        _openChildFeature(context, const PerkembanganPage());
                      },
                    ),

                    _serviceCard(
                      icon: Icons.vaccines_outlined,
                      title: 'Imunisasi',
                      subtitle: 'Jadwal & riwayat',
                      iconBackground: const Color(0xFFEAF3FA),
                      iconColor: primaryBlue,
                      onTap: () {
                        _openChildFeature(
                          context,
                          const RiwayatPage(onlyVaccinations: true),
                        );
                      },
                    ),

                    _serviceCard(
                      icon: Icons.history_rounded,
                      title: 'Riwayat Anak',
                      subtitle: 'Catatan kesehatan',
                      iconBackground: lavenderLight,
                      iconColor: lavender,
                      onTap: () {
                        _openChildFeature(context, const RiwayatPage());
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // =================================================
                // ARTIKEL
                // =================================================
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Artikel untuk Bunda',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        _open(context, const ArtikelPage());
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                      ),
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 1),

                const Text(
                  'Informasi sederhana untuk menemani tumbuh kembang si kecil.',
                  style: TextStyle(fontSize: 11, color: secondaryText),
                ),

                const SizedBox(height: 9),

                // =================================================
                // ARTIKEL 1
                // =================================================
                _buildArticleCard(
                  context: context,
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFF2E9B61),
                  category: 'GIZI ANAK',
                  title: 'Penuhi Gizi Si Kecil Sejak Dini',
                  description:
                      'Kenali pentingnya makanan bergizi untuk mendukung pertumbuhan anak.',
                  content: '''
Makanan bergizi merupakan bagian penting dalam mendukung pertumbuhan dan perkembangan anak.

Sejak dini, anak membutuhkan makanan yang beragam dan bergizi untuk membantu memenuhi kebutuhan tubuhnya. Orang tua dapat mengenalkan berbagai jenis makanan dengan memperhatikan sumber karbohidrat, protein, sayur, buah, dan kebutuhan cairan anak.

Selain memperhatikan jenis makanan, kebiasaan makan anak juga penting. Usahakan anak makan secara teratur dan biasakan mengonsumsi makanan yang bersih serta aman.

Orang tua juga dapat memantau kebiasaan makan dan pertumbuhan anak secara rutin melalui kegiatan Posyandu.

Jika anak memiliki kondisi khusus atau mengalami masalah makan, sebaiknya konsultasikan dengan tenaga kesehatan agar mendapatkan saran yang sesuai.
''',
                ),

                const SizedBox(height: 9),

                // =================================================
                // ARTIKEL 2
                // =================================================
                _buildArticleCard(
                  context: context,
                  icon: Icons.vaccines_rounded,
                  iconColor: const Color(0xFF2388D9),
                  category: 'IMUNISASI',
                  title: 'Mengapa Imunisasi Itu Penting?',
                  description:
                      'Kenali manfaat imunisasi dan ikuti jadwal sesuai anjuran tenaga kesehatan.',
                  content: '''
Imunisasi merupakan salah satu upaya penting untuk membantu melindungi anak dari penyakit tertentu yang dapat dicegah dengan imunisasi.

Melalui imunisasi, tubuh anak mendapatkan perlindungan sehingga dapat membantu mengurangi risiko terkena penyakit tertentu.

Pemberian imunisasi sebaiknya dilakukan sesuai jadwal yang dianjurkan oleh tenaga kesehatan. Orang tua dapat menyimpan catatan imunisasi anak agar jadwal yang sudah dilakukan dapat dipantau dengan baik.

Selain imunisasi, orang tua tetap perlu memperhatikan pola makan, kebersihan, istirahat, serta pertumbuhan dan perkembangan anak.

Jika memiliki pertanyaan mengenai jenis atau jadwal imunisasi, orang tua dapat berkonsultasi dengan kader atau tenaga kesehatan di Posyandu.
''',
                ),

                const SizedBox(height: 9),

                // =================================================
                // ARTIKEL 3
                // =================================================
                _buildArticleCard(
                  context: context,
                  icon: Icons.child_care_rounded,
                  iconColor: const Color(0xFFE58A25),
                  category: 'TUMBUH KEMBANG',
                  title: 'Pantau Pertumbuhan Anak Secara Rutin',
                  description:
                      'Pencatatan berat dan tinggi badan membantu memantau pertumbuhan anak.',
                  content: '''
Memantau pertumbuhan anak secara rutin membantu orang tua mengetahui perubahan kondisi anak dari waktu ke waktu.

Kegiatan Posyandu dapat menjadi salah satu kesempatan bagi orang tua untuk melakukan pemantauan pertumbuhan anak secara berkala.

Orang tua dapat membawa anak sesuai jadwal Posyandu dan menyimpan catatan hasil pengukuran seperti berat badan dan tinggi atau panjang badan.

Catatan pertumbuhan tersebut dapat membantu orang tua dan tenaga kesehatan melihat perkembangan anak serta menentukan apakah diperlukan pemeriksaan atau perhatian lebih lanjut.

Selain memantau pertumbuhan fisik, orang tua juga perlu memperhatikan perkembangan kemampuan anak sesuai usianya. Jika terdapat hal yang membuat khawatir, konsultasikan dengan tenaga kesehatan.
''',
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION BAR
      // ========================================================
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }
}
