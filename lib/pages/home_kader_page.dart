import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/design_tokens.dart';
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
            logError(error ?? status, 'realtime anak kader');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Pembaruan otomatis belum aktif. Tarik layar ke bawah untuk memperbarui.',
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
          SnackBar(
            content: Text(
              friendlyError(
                error,
                fallback:
                    'Ringkasan belum bisa dimuat. Tarik layar ke bawah untuk mencoba lagi.',
              ),
            ),
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      _refreshChildCount();
    });
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
    final name = displayNameFromUser(user, fallback: 'Kader');

    return Theme(
      data: AppTheme.kader,
      child: Scaffold(
        floatingActionButton: KaderCenterFab(
          onPressed: () {
            _open(context, const PemeriksaanPage(openFormOnStart: true));
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: 0,
          onTabSelected: (index) {
            _onNavigationTap(context, index);
          },
        ),

        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.md,
                AppSpace.page,
                AppSpace.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sapaan
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingNow(),
                              style: AppText.body.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.headline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      KaderLogoutButton(onPressed: () => _logout(context)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),

                  // Ringkasan dan aksi utama
                  FutureBuilder<int>(
                    future: _childCount,
                    builder: (context, snapshot) {
                      final countText = snapshot.hasError
                          ? 'Data anak belum bisa dimuat'
                          : !snapshot.hasData
                          ? 'Memuat data anak…'
                          : '${snapshot.data} anak terdaftar';

                      return KaderHeroCard(
                        dateLabel: tanggalLengkap(DateTime.now()),
                        countText: countText,
                        onRetry: snapshot.hasError ? _refreshChildCount : null,
                        onActionPressed: () {
                          _open(
                            context,
                            const PemeriksaanPage(openFormOnStart: true),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Cari
                  KaderSearchBar(
                    hintText: 'Cari nama anak atau NIK',
                    onTap: () {
                      _open(context, const DataAnakPage(isKader: true));
                    },
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // Layanan
                  const SectionHeader(title: 'Layanan'),
                  const SizedBox(height: AppSpace.md),
                  ServiceGrid(
                    children: [
                      ServiceTile(
                        icon: Icons.groups_outlined,
                        title: 'Monitoring Anak',
                        subtitle: 'Data & perkembangan',
                        onTap: () {
                          _open(context, const DataAnakPage(isKader: true));
                        },
                      ),
                      ServiceTile(
                        icon: Icons.monitor_weight_outlined,
                        title: 'Catat Gizi',
                        subtitle: 'Berat & tinggi',
                        onTap: () {
                          _open(
                            context,
                            const PemeriksaanPage(openFormOnStart: true),
                          );
                        },
                      ),
                      ServiceTile(
                        icon: Icons.vaccines_outlined,
                        title: 'Imunisasi',
                        subtitle: 'Catatan vaksin',
                        onTap: () {
                          _open(
                            context,
                            const ImunisasiPage(openFormOnStart: true),
                          );
                        },
                      ),
                      ServiceTile(
                        icon: Icons.calendar_month_outlined,
                        title: 'Jadwal',
                        subtitle: 'Jadwal posyandu',
                        onTap: () {
                          _open(context, const JadwalPage(isKader: true));
                        },
                      ),
                      ServiceTile(
                        icon: Icons.history_rounded,
                        title: 'Riwayat Global',
                        subtitle: 'Riwayat pemeriksaan',
                        onTap: () {
                          _open(context, const RiwayatPage(isKader: true));
                        },
                      ),
                      ServiceTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Profil',
                        subtitle: 'Data akun kader',
                        onTap: () {
                          _open(context, const ProfilPage());
                        },
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
