import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import 'data_anak_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'profil_page.dart';

class ArtikelPage extends StatelessWidget {
  const ArtikelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = [
      {
        'title': 'Pentingnya Imunisasi untuk Anak',
        'description':
            'Imunisasi membantu melindungi anak dari berbagai penyakit yang dapat dicegah.',
        'icon': Icons.vaccines_rounded,
        'color': const Color(0xFFE8F4FF),
        'iconColor': const Color(0xFF2388D9),
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
        'color': const Color(0xFFEAF8EF),
        'iconColor': const Color(0xFF2E9B61),
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
        'color': const Color(0xFFFFF3E5),
        'iconColor': const Color(0xFFE58A25),
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
        'color': const Color(0xFFF0EBFF),
        'iconColor': const Color(0xFF7656C8),
        'content': '''
Mengajarkan kebiasaan hidup bersih kepada anak dapat dilakukan sejak dini. Kebiasaan sederhana dapat dimulai dari mencuci tangan, menjaga kebersihan tubuh, dan menggunakan perlengkapan pribadi dengan baik.

Orang tua juga dapat memberikan contoh secara langsung karena anak biasanya belajar melalui kebiasaan yang mereka lihat di lingkungan sekitar.

Pastikan lingkungan tempat anak bermain dan beristirahat tetap bersih. Perhatikan juga kebersihan makanan dan minuman yang dikonsumsi anak.

Kebiasaan menjaga kebersihan yang dilakukan secara rutin dapat menjadi bagian dari pola hidup sehat anak sehari-hari.
''',
      },
    ];

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Artikel Kesehatan')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(
              'Bacaan untuk Bunda',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Informasi sederhana seputar kesehatan, gizi, dan tumbuh kembang anak.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // DAFTAR ARTIKEL
            ...articles.map(
              (article) => _ArticleCard(
                title: article['title'] as String,
                description: article['description'] as String,
                icon: article['icon'] as IconData,
                color: article['color'] as Color,
                iconColor: article['iconColor'] as Color,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailPage(
                        title: article['title'] as String,
                        content: article['content'] as String,
                        icon: article['icon'] as IconData,
                        iconColor: article['iconColor'] as Color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // BOTTOM NAVIGATION
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 3,
          onTap: (index) {
            final page = switch (index) {
              0 => const HomeOrtuPage(),
              1 => const DataAnakPage(),
              2 => const JadwalPage(),
              4 => const ProfilPage(),
              _ => null,
            };

            if (page != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Baca selengkapnya',
                            style: TextStyle(
                              color: iconColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: iconColor,
                            size: 16,
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
  final Color iconColor;

  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Artikel')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ARTIKEL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 52, color: iconColor),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ISI ARTIKEL
              ...content
                  .trim()
                  .split('\n\n')
                  .map(
                    (paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        paragraph.trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Color(0xFF0F172A),
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
