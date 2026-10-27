
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
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
  late Future<int> _childCount;
  late RealtimeChannel _childrenChannel;
  bool _realtimeErrorReported = false;

  @override
  void initState() {
    super.initState();
    _childCount = _loadChildCount();

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
                  'Pembaruan langsung data anak gagal: ${error ?? status}',
                ),
              ),
            );
          }
        });
  }

  Future<int> _loadChildCount() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw StateError('Sesi login tidak ditemukan.');
    }

    final rows = await Supabase.instance.client
        .from('anak')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  void _refreshChildCount() {
    if (mounted) {
      setState(() => _childCount = _loadChildCount());
    }
  }

  Future<void> _refresh() async {
    final nextCount = _loadChildCount();
    setState(() => _childCount = nextCount);

    try {
      await nextCount;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data anak: $error'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_childrenChannel);
    super.dispose();
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      _refreshChildCount();
    });
  }

  Future<void> _openChildFeature(
    BuildContext context,
    Widget page,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan masuk kembali untuk melanjutkan.',
          ),
        ),
      );
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
          const SnackBar(
            content: Text(
              'Tambahkan data anak terlebih dahulu.',
            ),
          ),
        );

        _open(context, const DataAnakPage());
        return;
      }

      _open(context, page);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memeriksa data anak: $error',
          ),
        ),
      );
    }
  }

  void _onNavigationTap(
    BuildContext context,
    int index,
  ) {
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

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal keluar dari akun: $error',
          ),
        ),
      );
    }
  }

  Widget _buildArticleCard(
    BuildContext context, {
    required IconData icon,
    required String category,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(
          context,
          const ArtikelPage(),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8EEE9),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 76,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF243047),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Baca artikel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.parent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.parent,
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final rawName = user?.userMetadata?['display_name'];

    final name = rawName is String &&
            rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Orang Tua';

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Belum ada notifikasi baru.',
                    ),
                  ),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.parentSoft,
                foregroundColor: AppColors.parent,
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
              ),
            ),
            LogoutButton(
              onPressed: () => _logout(context),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.parent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                2,
                18,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat pagi,',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    '$name!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KARTU JUMLAH ANAK
                  FutureBuilder<int>(
                    future: _childCount,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return HeroCard(
                          color: AppColors.parent,
                          child: Text(
                            'Data anak gagal dimuat: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const HeroCard(
                          color: AppColors.parent,
                          child: SizedBox(
                            height: 84,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }

                      final count = snapshot.data!;

                      if (count == 0) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.parentSoft,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            children: [
                              const ChildAvatar(size: 74),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada data si kecil',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tambahkan identitas anak terlebih dahulu '
                                'untuk melihat perkembangannya.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: () => _open(
                                  context,
                                  const DataAnakPage(),
                                ),
                                child: const Text(
                                  'Tambahkan data anak',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return HeroCard(
                        color: AppColors.parent,
                        child: Row(
                          children: [
                            const ChildAvatar(size: 56),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Data anak terdaftar',
                                    style: TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '$count anak',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _open(
                                context,
                                const DataAnakPage(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.parent,
                                backgroundColor:
                                    const Color(0xFFFFD84D),
                              ),
                              child: const Text('Lihat'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // MENU LAYANAN KELUARGA
                  const Text(
                    'Layanan keluarga',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 6,
                    childAspectRatio: .72,
                    children: [
                      MenuBubble(
                        icon: Icons.favorite_border_rounded,
                        label: 'Data Anak',
                        backgroundColor:
                            AppColors.menuBubbles[4].$1,
                        iconColor: AppColors.menuBubbles[4].$2,
                        onTap: () => _open(
                          context,
                          const DataAnakPage(),
                        ),
                      ),
                      MenuBubble(
                        icon: Icons.show_chart_rounded,
                        label: 'Grafik Tumbuh',
                        backgroundColor:
                            AppColors.menuBubbles[1].$1,
                        iconColor: AppColors.menuBubbles[1].$2,
                        onTap: () => _openChildFeature(
                          context,
                          const PerkembanganPage(),
                        ),
                      ),
                      MenuBubble(
                        icon: Icons.vaccines_outlined,
                        label: 'Imunisasi Anak',
                        backgroundColor:
                            AppColors.menuBubbles[2].$1,
                        iconColor: AppColors.menuBubbles[2].$2,
                        onTap: () => _openChildFeature(
                          context,
                          const RiwayatPage(
                            onlyVaccinations: true,
                          ),
                        ),
                      ),
                      MenuBubble(
                        icon: Icons.history_rounded,
                        label: 'Riwayat Anak',
                        backgroundColor:
                            AppColors.menuBubbles[3].$1,
                        iconColor: AppColors.menuBubbles[3].$2,
                        onTap: () => _openChildFeature(
                          context,
                          const RiwayatPage(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ARTIKEL UNTUK BUNDA
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Artikel untuk Bunda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _open(
                          context,
                          const ArtikelPage(),
                        ),
                        child: const Text('Lihat semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Informasi sederhana untuk menemani tumbuh '
                    'kembang si kecil.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildArticleCard(
                    context,
                    icon: Icons.restaurant_rounded,
                    category: 'Gizi Anak',
                    title: 'Penuhi Gizi Si Kecil Sejak Dini',
                    description:
                        'Kenali pentingnya makanan bergizi untuk '
                        'mendukung pertumbuhan dan perkembangan anak.',
                    backgroundColor: const Color(0xFFFFF0C2),
                    iconColor: const Color(0xFFB77900),
                  ),

                  const SizedBox(height: 12),

                  _buildArticleCard(
                    context,
                    icon: Icons.vaccines_rounded,
                    category: 'Imunisasi',
                    title: 'Mengapa Imunisasi Itu Penting?',
                    description:
                        'Kenali manfaat imunisasi dan ikuti jadwal '
                        'sesuai anjuran tenaga kesehatan.',
                    backgroundColor: const Color(0xFFFFE5D9),
                    iconColor: const Color(0xFFD85C32),
                  ),

                  const SizedBox(height: 12),

                  _buildArticleCard(
                    context,
                    icon: Icons.child_care_rounded,
                    category: 'Tumbuh Kembang',
                    title: 'Pantau Pertumbuhan Anak Secara Rutin',
                    description:
                        'Pencatatan berat dan tinggi badan membantu '
                        'orang tua memantau perubahan pertumbuhan anak.',
                    backgroundColor: const Color(0xFFDDF7E9),
                    iconColor: AppColors.parent,
                  ),
                ],
              ),
            ),
          ),
        ),

        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 0,
          onTap: (index) => _onNavigationTap(context, index),
        ),
      ),
    );
  }
}
