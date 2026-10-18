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
    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Artikel Kesehatan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.parentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.article_outlined,
                    color: AppColors.parent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Artikel belum tersedia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Belum ada sumber artikel kesehatan di aplikasi ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ),
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
              Navigator.push(
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
