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

  // =========================================================
  // WARNA KADER
  // =========================================================
  static const Color primaryBlue = Color(0xFF1261A0);
  static const Color navy = Color(0xFF123B5D);
  static const Color lavender = Color(0xFFA99BCF);
  static const Color lavenderSoft = Color(0xFFF4F1FA);
  static const Color blueSoft = Color(0xFFEAF3FA);
  static const Color textDark = Color(0xFF123B5D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

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
    if (mounted) {
      setState(() {
        _childCount = _loadChildCount();
      });
    }
  }

  Future<void> _refresh() async {
    final nextCount = _loadChildCount();

    setState(() {
      _childCount = nextCount;
    });

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

    if (page != null) {
      _open(context, page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final rawName =
        user?.userMetadata?['display_name'] ?? user?.userMetadata?['full_name'];

    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Kader';

    return Theme(
      data: AppTheme.kader.copyWith(
        scaffoldBackgroundColor: lavenderSoft,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),

      child: Scaffold(
        backgroundColor: lavenderSoft,

        // ===================================================
        // FAB
        // ===================================================
        floatingActionButton: KaderCenterFab(
          onPressed: () {
            _open(context, const PemeriksaanPage(openFormOnStart: true));
          },
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // ===================================================
        // BOTTOM NAVIGATION
        // ===================================================
        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: 0,
          onTabSelected: (index) {
            _onNavigationTap(context, index);
          },
        ),

        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: primaryBlue,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // =================================================
                  // HEADER
                  // =================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Halo, $name!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: GoogleFonts.fredoka(
                                color: navy,
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Posyandu · Layanan hari ini',
                              style: GoogleFonts.nunito(
                                color: textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // LOGOUT
                      KaderLogoutButton(onPressed: () => _logout(context)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // HERO CARD
                  // =================================================
                  FutureBuilder<int>(
                    future: _childCount,

                    builder: (context, snapshot) {
                      final now = DateTime.now();

                      const months = [
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'Mei',
                        'Jun',
                        'Jul',
                        'Agt',
                        'Sep',
                        'Okt',
                        'Nov',
                        'Des',
                      ];

                      final dateLabel =
                          'Kegiatan hari ini · '
                          '${now.day} '
                          '${months[now.month - 1]}';

                      final countText = snapshot.hasError
                          ? 'Data belum tersedia'
                          : !snapshot.hasData
                          ? 'Memuat data anak...'
                          : '${snapshot.data} anak terdaftar';

                      return KaderHeroCard(
                        dateLabel: dateLabel,

                        countText: countText,

                        onActionPressed: () {
                          _open(
                            context,
                            const PemeriksaanPage(openFormOnStart: true),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // SEARCH
                  // =================================================
                  KaderSearchBar(
                    hintText: 'Cari nama anak atau NIK',

                    onTap: () {
                      _open(context, const DataAnakPage(isKader: true));
                    },
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // LAYANAN
                  // =================================================
                  Text(
                    'Layanan',

                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =================================================
                  // 6 MENU - 2 KOLOM
                  // =================================================
                  GridView.count(
                    crossAxisCount: 2,

                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    crossAxisSpacing: 12,

                    mainAxisSpacing: 12,

                    childAspectRatio: 1.55,

                    children: [
                      // 1. MONITORING ANAK
                      _buildServiceCard(
                        icon: Icons.groups_outlined,

                        title: 'Monitoring Anak',

                        subtitle: 'Data & perkembangan',

                        background: blueSoft,

                        iconColor: primaryBlue,

                        onTap: () {
                          _open(context, const DataAnakPage(isKader: true));
                        },
                      ),

                      // 2. CATAT GIZI
                      _buildServiceCard(
                        icon: Icons.monitor_weight_outlined,

                        title: 'Catat Gizi',

                        subtitle: 'Berat & tinggi',

                        background: lavenderSoft,

                        iconColor: lavender,

                        onTap: () {
                          _open(
                            context,
                            const PemeriksaanPage(openFormOnStart: true),
                          );
                        },
                      ),

                      // 3. IMUNISASI
                      _buildServiceCard(
                        icon: Icons.vaccines_outlined,

                        title: 'Imunisasi',

                        subtitle: 'Catatan vaksin',

                        background: const Color(0xFFF1F5F9),

                        iconColor: primaryBlue,

                        onTap: () {
                          _open(
                            context,
                            const ImunisasiPage(openFormOnStart: true),
                          );
                        },
                      ),

                      // 4. JADWAL
                      _buildServiceCard(
                        icon: Icons.calendar_month_outlined,

                        title: 'Jadwal',

                        subtitle: 'Jadwal posyandu',

                        background: const Color(0xFFF4F1FA),

                        iconColor: const Color(0xFF7D6DA8),

                        onTap: () {
                          _open(context, const JadwalPage(isKader: true));
                        },
                      ),

                      // 5. RIWAYAT GLOBAL
                      _buildServiceCard(
                        icon: Icons.history_rounded,

                        title: 'Riwayat Global',

                        subtitle: 'Riwayat pemeriksaan',

                        background: blueSoft,

                        iconColor: navy,

                        onTap: () {
                          _open(context, const RiwayatPage(isKader: true));
                        },
                      ),

                      // 6. PROFIL
                      _buildServiceCard(
                        icon: Icons.person_outline_rounded,

                        title: 'Profil',

                        subtitle: 'Data akun kader',

                        background: lavenderSoft,

                        iconColor: const Color(0xFF8B7BB8),

                        onTap: () {
                          _open(context, const ProfilPage());
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // INFO BAWAH
                  // =================================================
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(16),

                      border: Border.all(color: border),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,

                          decoration: BoxDecoration(
                            color: blueSoft,
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.health_and_safety_outlined,
                            color: primaryBlue,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                'Layanan Posyandu',
                                style: GoogleFonts.nunito(
                                  color: navy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                'Kelola data dan layanan kesehatan anak dengan mudah.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,

                                style: GoogleFonts.nunito(
                                  color: textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SERVICE CARD
  // =============================================================
  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(13),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: border, width: 1),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),

                blurRadius: 10,

                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              // ICON
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(icon, color: iconColor, size: 23),
              ),

              const SizedBox(width: 10),

              // TEXT
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: GoogleFonts.nunito(
                        color: navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: GoogleFonts.nunito(
                        color: textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
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
}