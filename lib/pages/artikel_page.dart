import 'package:flutter/material.dart';

import '../widgets/app_components.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import 'data_anak_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'profil_page.dart';

class ArtikelPage extends StatelessWidget {
  const ArtikelPage({super.key});

  static const _articles = [
    {
      'title': 'Pentingnya Imunisasi untuk Anak',
      'description':
          'Imunisasi membantu melindungi anak dari berbagai penyakit yang dapat dicegah.',
      'icon': Icons.vaccines_rounded,
      'content': '''
Imunisasi merupakan salah satu cara penting untuk membantu menjaga kesehatan anak. Dengan imunisasi, tubuh anak mendapatkan perlindungan terhadap penyakit tertentu.

Pemberian imunisasi sebaiknya dilakukan sesuai jadwal yang dianjurkan oleh tenaga kesehatan. Orang tua dapat mencatat jadwal imunisasi anak agar tidak ada pemberian imunisasi yang terlewat.

Selain imunisasi, orang tua juga tetap perlu memperhatikan pola makan, kebersihan, istirahat, serta pertumbuhan dan perkembangan anak.

Jika memiliki pertanyaan mengenai jenis atau jadwal imunisasi anak, orang tua dapat berkonsultasi langsung dengan kader atau tenaga kesehatan di Posyandu.
''',
    },
    {
      'title': 'Makanan Bergizi untuk Tumbuh Kembang Anak',
      'description':
          'Penuhi kebutuhan nutrisi anak dengan makanan yang beragam dan bergizi.',
      'icon': Icons.restaurant_rounded,
      'content': '''
Makanan bergizi berperan penting dalam mendukung pertumbuhan dan perkembangan anak. Anak membutuhkan berbagai zat gizi agar dapat tumbuh dengan baik dan tetap aktif.

Orang tua dapat memberikan makanan yang beragam dengan memperhatikan sumber karbohidrat, protein, sayur, buah, serta kebutuhan cairan anak.

Tidak hanya jenis makanan, kebiasaan makan juga perlu diperhatikan. Usahakan anak makan secara teratur dan biasakan mengonsumsi makanan yang dibuat dengan bahan yang bersih dan aman.

Jika anak memiliki kondisi khusus atau mengalami masalah makan, orang tua sebaiknya berkonsultasi dengan tenaga kesehatan untuk mendapatkan saran yang sesuai.
''',
    },
    {
      'title': 'Memantau Pertumbuhan Anak di Posyandu',
      'description':
          'Pantau berat badan dan perkembangan anak secara rutin melalui kegiatan Posyandu.',
      'icon': Icons.child_care_rounded,
      'content': '''
Posyandu menjadi salah satu tempat bagi orang tua untuk memantau pertumbuhan dan kesehatan anak secara berkala.

Melalui kegiatan Posyandu, orang tua dapat memperoleh informasi mengenai kondisi pertumbuhan anak dan mendapatkan edukasi kesehatan dari kader maupun tenaga kesehatan.

Pemeriksaan yang dilakukan secara rutin dapat membantu orang tua mengetahui perubahan kondisi anak dari waktu ke waktu.

Karena itu, orang tua disarankan untuk membawa anak ke Posyandu sesuai jadwal dan menyimpan catatan hasil pemeriksaan anak dengan baik.
''',
    },
    {
      'title': 'Tips Menjaga Kebersihan Anak',
      'description':
          'Kebiasaan sederhana menjaga kebersihan dapat membantu anak tetap sehat.',
      'icon': Icons.clean_hands_rounded,
      'content': '''
Mengajarkan kebiasaan hidup bersih kepada anak dapat dilakukan sejak dini. Kebiasaan sederhana dapat dimulai dari mencuci tangan, menjaga kebersihan tubuh, dan menggunakan perlengkapan pribadi dengan baik.

Orang tua juga dapat memberikan contoh secara langsung karena anak biasanya belajar melalui kebiasaan yang mereka lihat di lingkungan sekitar.

Pastikan lingkungan tempat anak bermain dan beristirahat tetap bersih. Perhatikan juga kebersihan makanan dan minuman yang dikonsumsi anak.

Kebiasaan menjaga kebersihan yang dilakukan secara rutin dapat menjadi bagian dari pola hidup sehat anak sehari-hari.
''',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Artikel Kesehatan')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.page,
            AppSpace.page,
            100,
          ),
          children: [
            Text(
              'Bacaan Kesehatan Anak',
              style: AppText.headline,
            ),
            const SizedBox(height: 6),
            Text(
              'Informasi sederhana seputar kesehatan, gizi, dan tumbuh kembang anak.',
              style: AppText.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // DAFTAR ARTIKEL
            for (var i = 0; i < _articles.length; i++) ...[
              _ArticleCard(
                title: _articles[i]['title'] as String,
                description: _articles[i]['description'] as String,
                icon: _articles[i]['icon'] as IconData,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailPage(
                        title: _articles[i]['title'] as String,
                        content: _articles[i]['content'] as String,
                        icon: _articles[i]['icon'] as IconData,
                        iconColor: scheme.primary,
                      ),
                    ),
                  );
                },
              ),
              if (i < _articles.length - 1)
                const SizedBox(height: AppSpace.md),
            ],
          ],
        ),

        // BOTTOM NAVIGATION
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 3,
          onTap: (index) {
            if (index == 3) return;
            final page = switch (index) {
              0 => const HomeOrtuPage(),
              1 => const DataAnakPage(),
              2 => const JadwalPage(),
              4 => const ProfilPage(),
              _ => null,
            };

            if (page != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            }
          },
        ),
      ),
    );
  }
}

// =======================================================
// CARD ARTIKEL
// =======================================================

class _ArticleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
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
            child: Icon(icon, color: scheme.primary, size: 24),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.subtitle,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Baca selengkapnya',
                      style: AppText.caption.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.primary,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// DETAIL ARTIKEL
// =======================================================

class ArticleDetailPage extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color? iconColor;

  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = iconColor ?? scheme.primary;

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Artikel')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.page,
            AppSpace.page,
            AppSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ARTIKEL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.xl),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadius.cardAll,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Icon(icon, size: 32, color: primaryColor),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppText.title,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpace.xl),

              // ISI ARTIKEL
              ...content
                  .trim()
                  .split('\n\n')
                  .map(
                    (paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.lg),
                      child: Text(
                        paragraph.trim(),
                        style: AppText.bodyLarge.copyWith(
                          height: 1.65,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
