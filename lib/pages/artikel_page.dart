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
      'category': 'Imunisasi',
      'readTime': '3 mnt baca',
      'description':
          'Imunisasi membantu melindungi anak dari berbagai penyakit berbahaya yang dapat dicegah sejak dini.',
      'image': 'assets/images/artikel_imunisasi.png',
      'icon': Icons.vaccines_rounded,
      'gradient': [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      'accentColor': Color(0xFF2563EB),
      'content': '''
Imunisasi merupakan salah satu cara paling efektif untuk membangun kekebalan tubuh anak terhadap berbagai penyakit menular yang berbahaya.

Pemberian imunisasi sebaiknya dilakukan sesuai jadwal dasar yang dianjurkan oleh Kementerian Kesehatan dan tenaga medis. Orang tua dapat memantau catatan imunisasi di menu Riwayat Anak agar tidak ada jadwal yang terlewat.

Setelah imunisasi, anak mungkin mengalami reaksi ringan seperti demam tidak tinggi atau kemerahan di area suntikan. Hal tersebut wajar sebagai tanda tubuh sedang membentuk antibodi.

Jika memiliki pertanyaan mengenai jenis vaksin atau jadwal imunisasi susulan, orang tua dapat berkonsultasi langsung dengan kader atau bidan di Posyandu terdekat.
''',
    },
    {
      'title': 'Makanan Bergizi untuk Tumbuh Kembang Anak',
      'category': 'Nutrisi & Gizi',
      'readTime': '4 mnt baca',
      'description':
          'Penuhi kebutuhan nutrisi harian si kecil dengan menu beragam, tinggi protein hewani, dan bergizi seimbang.',
      'image': 'assets/images/artikel_gizi.png',
      'icon': Icons.restaurant_rounded,
      'gradient': [Color(0xFF047857), Color(0xFF10B981)],
      'accentColor': Color(0xFF059669),
      'content': '''
Makanan bergizi seimbang berperan vital dalam mendukung pertumbuhan fisik dan perkembangan otak anak, terutama pada masa emas 1.000 hari pertama kehidupan.

Pastikan setiap porsi makan anak mengandung sumber karbohidrat, protein hewani (seperti telur, ikan, ayam, atau daging), lemak sehat, serta sayur dan buah secara bertahap sesuai usia.

Selain komposisi gizi, jadwal makan yang teratur dan suasana makan yang menyenangkan tanpa paksaan membantu anak membangun kebiasaan makan yang baik.

Apabila berat badan anak tidak naik selama dua bulan berturut-turut, segera konsultasikan dengan kader Posyandu atau ahli gizi Puskesmas untuk mendapatkan pendampingan MPASI/PMT.
''',
    },
    {
      'title': 'Memantau Pertumbuhan Anak di Posyandu',
      'category': 'Tumbuh Kembang',
      'readTime': '3 mnt baca',
      'description':
          'Pantau berat badan, tinggi badan, dan grafik KMS anak secara rutin setiap bulan di Posyandu.',
      'image': 'assets/images/artikel_pertumbuhan.png',
      'icon': Icons.child_care_rounded,
      'gradient': [Color(0xFFD97706), Color(0xFFF59E0B)],
      'accentColor': Color(0xFFD97706),
      'content': '''
Kunjungan rutin ke Posyandu setiap bulan membantu orang tua memantau kurva pertumbuhan anak secara akurat melalui penimbangan berat badan dan pengukuran tinggi badan.

Melalui grafik KMS Digital pada aplikasi SI-POSYANDU, orang tua dapat langsung melihat apakah pertumbuhan berat badan anak berada pada pita hijau (normal) atau memerlukan perhatian khusus.

Deteksi dini gangguan pertumbuhan sangat penting agar pencegahan stunting dan masalah gizi dapat dilakukan sedini mungkin dengan hasil yang optimal.

Biasakan membawa anak ke Posyandu sesuai jadwal yang tertera di menu Jadwal Posyandu agar riwayat kesehatannya tercatat lengkap.
''',
    },
    {
      'title': 'Tips Menjaga Kebersihan Anak Sehari-hari',
      'category': 'Pola Hidup Sehat',
      'readTime': '2 mnt baca',
      'description':
          'Kebiasaan sederhana seperti mencuci tangan pakai sabun dapat mencegah anak dari infeksi dan diare.',
      'image': 'assets/images/artikel_kebersihan.png',
      'icon': Icons.clean_hands_rounded,
      'gradient': [Color(0xFF0369A1), Color(0xFF0EA5E9)],
      'accentColor': Color(0xFF0284C7),
      'content': '''
Mengajarkan perilaku hidup bersih dan sehat (PHBS) kepada anak dapat dimulai sejak dini melalui kebiasaan sederhana di rumah.

Biasakan anak mencuci tangan menggunakan air mengalir dan sabun sebelum makan, setelah bermain di luar rumah, dan setelah menggunakan toilet.

Pastikan juga kebersihan mainan, peralatan makan, serta kuku anak selalu terjaga, dan gunakan air matang yang bersih untuk kebutuhan minum maupun mengolah makanan anak.

Kebiasaan bersih yang dicontohkan orang tua setiap hari akan menjadi perlindungan alami terbaik agar anak tetap aktif, ceria, dan jarang sakit.
''',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Artikel Kesehatan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
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
              'Informasi praktis seputar imunisasi, gizi, dan tumbuh kembang si kecil.',
              style: AppText.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // DAFTAR ARTIKEL DENGAN BANNER VISUAL
            for (var i = 0; i < _articles.length; i++) ...[
              _ArticleCard(
                title: _articles[i]['title'] as String,
                category: _articles[i]['category'] as String,
                readTime: _articles[i]['readTime'] as String,
                description: _articles[i]['description'] as String,
                imagePath: _articles[i]['image'] as String,
                icon: _articles[i]['icon'] as IconData,
                gradient: _articles[i]['gradient'] as List<Color>,
                accentColor: _articles[i]['accentColor'] as Color,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailPage(
                        title: _articles[i]['title'] as String,
                        category: _articles[i]['category'] as String,
                        readTime: _articles[i]['readTime'] as String,
                        content: _articles[i]['content'] as String,
                        imagePath: _articles[i]['image'] as String,
                        icon: _articles[i]['icon'] as IconData,
                        gradient: _articles[i]['gradient'] as List<Color>,
                        accentColor: _articles[i]['accentColor'] as Color,
                      ),
                    ),
                  );
                },
              ),
              if (i < _articles.length - 1)
                const SizedBox(height: AppSpace.lg),
            ],
          ],
        ),

        // BOTTOM NAVIGATION
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 0,
          onTap: (index) {
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
// BANNER VISUAL ARTIKEL (GAMBAR ASET / ILUSTRASI GRADIEN)
// =======================================================

class _ArticleVisualBanner extends StatelessWidget {
  final String imagePath;
  final IconData icon;
  final List<Color> gradient;
  final String category;
  final double height;

  const _ArticleVisualBanner({
    required this.imagePath,
    required this.icon,
    required this.gradient,
    required this.category,
    this.height = 148,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Latar gradien penuh warna + dekorasi ilustrasi
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -24,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -40,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Jika file gambar aset tersedia, otomatis tampil menimpa gradien
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          // Badge kategori di pojok kiri atas
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: gradient.first,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// CARD ARTIKEL
// =======================================================

class _ArticleCard extends StatelessWidget {
  final String title;
  final String category;
  final String readTime;
  final String description;
  final String imagePath;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.title,
    required this.category,
    required this.readTime,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArticleVisualBanner(
              imagePath: imagePath,
              icon: icon,
              gradient: gradient,
              category: category,
              height: 140,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.subtitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            readTime,
                            style: AppText.caption.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Baca selengkapnya',
                            style: AppText.caption.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: accentColor,
                            size: 15,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
  final String category;
  final String readTime;
  final String content;
  final String imagePath;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;

  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.category,
    required this.readTime,
    required this.content,
    required this.imagePath,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Detail Artikel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNER HEADER ARTIKEL
              _ArticleVisualBanner(
                imagePath: imagePath,
                icon: icon,
                gradient: gradient,
                category: category,
                height: 200,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.xl,
                  AppSpace.page,
                  AppSpace.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$readTime · Edukasi Posyandu',
                          style: AppText.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: AppText.headline.copyWith(
                        fontSize: 22,
                        height: 1.3,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppColors.divider),
                    ),

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
                                height: 1.7,
                                color: AppColors.text,
                              ),
                            ),
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