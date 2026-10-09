import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/menu_card.dart';
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
  static const _primary = Color(0xFF13835F);
  static const _accent = Color(0xFF39A980);
  static const _background = Color(0xFFF8FAFC);

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
    if (user == null) throw StateError('Sesi login tidak ditemukan.');
    final rows = await Supabase.instance.client
        .from('anak')
        .select('id')
        .eq('user_id', user.id);
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
          SnackBar(content: Text('Gagal memuat data anak: $error')),
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

  Future<void> _openChildFeature(BuildContext context, Widget page) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk kembali untuk melanjutkan.'),
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final rawName = user?.userMetadata?['display_name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Orang Tua';
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SI-Posyandu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar akun',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name!',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pantau tumbuh kembang si kecil dengan mudah.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<int>(
                  future: _childCount,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ChildSummary(
                        accentColor: _primary,
                        title: 'Data Anak',
                        message: 'Data belum dapat dimuat: ${snapshot.error}',
                        icon: Icons.cloud_off_outlined,
                      );
                    }
                    if (!snapshot.hasData) {
                      return const _ChildSummary(
                        accentColor: _primary,
                        title: 'Data Anak',
                        message: 'Memuat data anak Anda...',
                        icon: Icons.child_care_rounded,
                      );
                    }
                    final count = snapshot.data!;
                    return _ChildSummary(
                      accentColor: _primary,
                      title: count == 0 ? 'Data Anak Kosong' : 'Anak Terdaftar',
                      message: count == 0
                          ? 'Tambahkan identitas anak melalui menu Data Anak.'
                          : '$count anak terdaftar',
                      icon: count == 0
                          ? Icons.info_outline_rounded
                          : Icons.child_care_rounded,
                    );
                  },
                ),
                const SizedBox(height: 26),
                const Text(
                  'Layanan Keluarga',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.98,
                  children: [
                    MenuCard(
                      title: 'Data Anak',
                      subtitle: 'Daftarkan dan lihat anak Anda',
                      icon: Icons.child_care_rounded,
                      accentColor: _primary,
                      onTap: () =>
                          _open(context, const DataAnakPage(isKader: false)),
                    ),
                    MenuCard(
                      title: 'Grafik Tumbuh',
                      subtitle: 'Pantau status KMS si kecil',
                      icon: Icons.show_chart_rounded,
                      accentColor: _accent,
                      onTap: () =>
                          _openChildFeature(context, const PerkembanganPage()),
                    ),
                    MenuCard(
                      title: 'Jadwal Posyandu',
                      subtitle: 'Lihat jadwal layanan terbaru',
                      icon: Icons.calendar_month_rounded,
                      accentColor: const Color(0xFF4E9E78),
                      onTap: () => _open(context, const JadwalPage()),
                    ),
                    MenuCard(
                      title: 'Riwayat Anak',
                      subtitle: 'Lihat pemeriksaan dan imunisasi',
                      icon: Icons.history_rounded,
                      accentColor: const Color(0xFF548E82),
                      onTap: () =>
                          _openChildFeature(context, const RiwayatPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ProfileLink(
                  accentColor: _primary,
                  onTap: () => _open(context, const ProfilPage()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildSummary extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String message;
  final IconData icon;

  const _ChildSummary({
    required this.accentColor,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF178862), Color(0xFF57B991)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.9)),
        ],
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const _ProfileLink({required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.account_circle_outlined, color: accentColor, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil Saya',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Kelola informasi akun',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }
}
