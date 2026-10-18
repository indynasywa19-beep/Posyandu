import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_theme.dart';
import '../widgets/kader_widgets.dart';
import 'data_anak_page.dart';
import 'imunisasi_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'pemeriksaan_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

class HomeKaderPage extends StatefulWidget {
  const HomeKaderPage({super.key});

  @override
  State<HomeKaderPage> createState() => _HomeKaderPageState();
}

class _HomeKaderPageState extends State<HomeKaderPage> {
  late Future<int> _childCount;
  late RealtimeChannel _childrenChannel;
  bool _realtimeErrorReported = false;

  @override
  void initState() {
    super.initState();
    _childCount = _loadChildCount();
    _childrenChannel = Supabase.instance.client
        .channel('dashboard-kader-anak')
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
                  'Pembaruan langsung monitoring gagal: ${error ?? status}',
                ),
              ),
            );
          }
        });
  }

  Future<int> _loadChildCount() async {
    final rows = await Supabase.instance.client.from('anak').select('id');
    return rows.length;
  }

  void _refreshChildCount() {
    if (mounted) setState(() => _childCount = _loadChildCount());
  }

  Future<void> _refresh() async {
    final nextCount = _loadChildCount();
    setState(() => _childCount = nextCount);
    try {
      await nextCount;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat ringkasan monitoring: $error')),
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      _refreshChildCount();
    });
  }

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

  void _onNavigationTap(BuildContext context, int index) {
    final page = switch (index) {
      1 => const DataAnakPage(isKader: true),
      2 => const JadwalPage(isKader: true),
      3 => const ProfilPage(),
      _ => null,
    };
    if (page != null) _open(context, page);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final rawName = user?.userMetadata?['display_name'] ??
        user?.userMetadata?['full_name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Kader';

    return Theme(
      data: AppTheme.kader.copyWith(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: KaderCenterFab(
          onPressed: () => _open(
            context,
            const PemeriksaanPage(openFormOnStart: true),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: 0,
          onTabSelected: (index) => _onNavigationTap(context, index),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF1D4ED8),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header greeting & logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, $name!',
                              style: GoogleFonts.fredoka(
                                color: const Color(0xFF0F172A),
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Posyandu · Layanan hari ini',
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      KaderLogoutButton(onPressed: () => _logout(context)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Hero Card
                  FutureBuilder<int>(
                    future: _childCount,
                    builder: (context, snapshot) {
                      final now = DateTime.now();
                      const months = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
                      ];
                      final dateLabel =
                          'Kegiatan hari ini · ${now.day} ${months[now.month - 1]}';

                      final countText = snapshot.hasError
                          ? 'Data belum tersedia'
                          : !snapshot.hasData
                              ? 'Memuat data anak...'
                              : '${snapshot.data} anak terdaftar';

                      return KaderHeroCard(
                        dateLabel: dateLabel,
                        countText: countText,
                        onActionPressed: () => _open(
                          context,
                          const PemeriksaanPage(openFormOnStart: true),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Search Bar Pill
                  KaderSearchBar(
                    hintText: 'Cari nama anak atau NIK',
                    onTap: () => _open(
                      context,
                      const DataAnakPage(isKader: true),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Layanan Section Title
                  Text(
                    'Layanan',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Layanan 2x3 Grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisExtent: 110,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                    children: [
                      KaderMenuBubble(
                        icon: Icons.groups_outlined,
                        label: 'Monitoring Anak',
                        backgroundColor: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF1D4ED8),
                        onTap: () => _open(
                          context,
                          const DataAnakPage(isKader: true),
                        ),
                      ),
                      KaderMenuBubble(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Catat Gizi',
                        backgroundColor: const Color(0xFFD1FAE5),
                        iconColor: const Color(0xFF047857),
                        onTap: () => _open(
                          context,
                          const PemeriksaanPage(openFormOnStart: true),
                        ),
                      ),
                      KaderMenuBubble(
                        icon: Icons.vaccines_outlined,
                        label: 'Imunisasi',
                        backgroundColor: const Color(0xFFFFE4D6),
                        iconColor: const Color(0xFFC2410C),
                        onTap: () => _open(
                          context,
                          const ImunisasiPage(openFormOnStart: true),
                        ),
                      ),
                      KaderMenuBubble(
                        icon: Icons.calendar_month_outlined,
                        label: 'Jadwal',
                        backgroundColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFB45309),
                        onTap: () => _open(
                          context,
                          const JadwalPage(isKader: true),
                        ),
                      ),
                      KaderMenuBubble(
                        icon: Icons.history_rounded,
                        label: 'Riwayat Global',
                        backgroundColor: const Color(0xFFEDE9FE),
                        iconColor: const Color(0xFF6D28D9),
                        onTap: () => _open(
                          context,
                          const RiwayatPage(isKader: true),
                        ),
                      ),
                      KaderMenuBubble(
                        icon: Icons.person_outline_rounded,
                        label: 'Profil',
                        backgroundColor: const Color(0xFFFCE7F3),
                        iconColor: const Color(0xFFBE185D),
                        onTap: () => _open(context, const ProfilPage()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
