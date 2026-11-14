import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
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
              logError(error ?? status, 'realtime anak');

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
  }

  // ---------------------------------------------------------------------------
  // DATA ANAK
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // NAVIGASI
  // ---------------------------------------------------------------------------
  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      _refreshChildCount();
    });
  }

  void _onNavigationTap(int index) {
    final Widget? page = switch (index) {
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
        SnackBar(
          content: Text(
            friendlyError(
              error,
              fallback: 'Data anak belum bisa diperiksa. Coba lagi.',
            ),
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // KELUAR AKUN
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = displayNameFromUser(user, fallback: 'Bapak/Ibu');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        titleSpacing: AppSpace.page,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadius.controlAll,
              ),
              child: Icon(
                Icons.health_and_safety_rounded,
                color: scheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpace.sm + 2),
            Flexible(
              child: Text(
                'SI-POSYANDU',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(fontSize: 16, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
        actions: [
          LogoutButton(onPressed: () => _logout(context)),
          const SizedBox(width: AppSpace.md),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpace.page,
              AppSpace.sm,
              AppSpace.page,
              AppSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sapaan
                Text(
                  greetingNow(),
                  style: AppText.body.copyWith(color: AppColors.secondaryText),
                ),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.headline,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Pantau kesehatan dan tumbuh kembang si kecil.',
                  style: AppText.body.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: AppSpace.lg),

                // Ringkasan data anak
                FutureBuilder<int>(
                  future: _childCount,
                  builder: (context, snapshot) {
                    return _ChildSummaryCard(
                      snapshot: snapshot,
                      onOpen: () => _open(context, const DataAnakPage()),
                      onRetry: _refreshChildCount,
                    );
                  },
                ),
                const SizedBox(height: AppSpace.xl),

                // Layanan
                const SectionHeader(
                  title: 'Layanan keluarga',
                  subtitle: 'Akses informasi kesehatan si kecil.',
                ),
                const SizedBox(height: AppSpace.md),
                ServiceGrid(
                  children: [
                    ServiceTile(
                      icon: Icons.child_care_rounded,
                      title: 'Data Anak',
                      subtitle: 'Identitas si kecil',
                      onTap: () => _open(context, const DataAnakPage()),
                    ),
                    ServiceTile(
                      icon: Icons.show_chart_rounded,
                      title: 'Grafik Tumbuh',
                      subtitle: 'Pantau perkembangan',
                      onTap: () =>
                          _openChildFeature(context, const PerkembanganPage()),
                    ),
                    ServiceTile(
                      icon: Icons.vaccines_outlined,
                      title: 'Imunisasi',
                      subtitle: 'Jadwal & riwayat',
                      onTap: () => _openChildFeature(
                        context,
                        const RiwayatPage(onlyVaccinations: true),
                      ),
                    ),
                    ServiceTile(
                      icon: Icons.history_rounded,
                      title: 'Riwayat Anak',
                      subtitle: 'Catatan kesehatan',
                      onTap: () =>
                          _openChildFeature(context, const RiwayatPage()),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),

                // Artikel
                SectionHeader(
                  title: 'Artikel untuk orang tua',
                  subtitle:
                      'Informasi sederhana untuk menemani tumbuh kembang si kecil.',
                  actionLabel: 'Lihat semua',
                  onAction: () => _open(context, const ArtikelPage()),
                ),
                const SizedBox(height: AppSpace.md),
                for (var i = 0; i < _articles.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpace.md),
                  _ArticleCard(article: _articles[i]),
                ],
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: AppBottomNav(
        isKader: false,
        selectedIndex: 0,
        onTap: _onNavigationTap,
      ),
    );
  }
}

// =============================================================================
// RINGKASAN DATA ANAK
// =============================================================================
class _ChildSummaryCard extends StatelessWidget {
  final AsyncSnapshot<int> snapshot;
  final VoidCallback onOpen;
  final VoidCallback onRetry;

  const _ChildSummaryCard({
    required this.snapshot,
    required this.onOpen,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppStatus.danger.icon, color: AppStatus.danger.foreground),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data anak belum bisa dimuat',
                        style: AppText.subtitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Periksa koneksi internet Anda, lalu coba lagi.',
                        style: AppText.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            AppButton(
              label: 'Coba lagi',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              expand: false,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      );
    }

    if (!snapshot.hasData) {
      return const AppCard(child: SizedBox(height: 60, child: LoadingState()));
    }

    final count = snapshot.data!;

    if (count == 0) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconBadge(icon: Icons.child_care_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Belum ada data si kecil', style: AppText.subtitle),
                      const SizedBox(height: 2),
                      Text(
                        'Tambahkan data anak untuk mulai memantau perkembangannya.',
                        style: AppText.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(label: 'Tambah data anak', onPressed: onOpen),
          ],
        ),
      );
    }

    return AppCard(
      child: Row(
        children: [
          const _IconBadge(icon: Icons.child_care_rounded),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data anak terdaftar', style: AppText.caption),
                Text('$count anak', style: AppText.title),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          AppButton(
            label: 'Lihat',
            onPressed: onOpen,
            expand: false,
            variant: AppButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.controlAll,
      ),
      child: Icon(icon, size: 28, color: scheme.primary),
    );
  }
}

// =============================================================================
// ARTIKEL
// =============================================================================
class _Article {
  final IconData icon;
  final Color iconColor;
  final String category;
  final String title;
  final String description;
  final String content;

  const _Article({
    required this.icon,
    required this.iconColor,
    required this.category,
    required this.title,
    required this.description,
    required this.content,
  });
}

class _ArticleCard extends StatelessWidget {
  final _Article article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailPage(
              title: article.title,
              content: article.content,
              icon: article.icon,
              iconColor: article.iconColor,
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.controlAll,
            ),
            child: Icon(article.icon, size: 24, color: scheme.primary),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.category,
                  style: AppText.caption.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  article.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _articles = <_Article>[
  _Article(
    icon: Icons.restaurant_rounded,
    iconColor: Color(0xFF2E9B61),
    category: 'Gizi anak',
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
  _Article(
    icon: Icons.vaccines_rounded,
    iconColor: Color(0xFF2388D9),
    category: 'Imunisasi',
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
  _Article(
    icon: Icons.child_care_rounded,
    iconColor: Color(0xFFE58A25),
    category: 'Tumbuh kembang',
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
];
