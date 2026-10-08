import 'package:flutter/material.dart';

import '../widgets/menu_card.dart';
import 'data_anak_page.dart';
import 'pemeriksaan_page.dart';
import 'imunisasi_page.dart';
import 'jadwal_page.dart';
import 'profil_page.dart';
import 'perkembangan_page.dart';
import 'riwayat_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SI-Posyandu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      // =========================
      // BODY
      // =========================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SAPAAN
            const Text(
              'Halo, Indy!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              'Pantau kesehatan dan tumbuh kembang anak.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 20),

            // =========================
            // DATA ANAK
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.child_care,
                      size: 35,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Anak',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Aisyah Putri',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          '3 Tahun • Perempuan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // LAYANAN
            // =========================
            const Text(
              'Layanan',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // =========================
            // MENU BARIS 1
            // =========================
            Row(
              children: [
                Expanded(
                  child: MenuCard(
                    icon: Icons.child_care,
                    title: 'Data Anak',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataAnakPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: MenuCard(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Perkembangan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PerkembanganPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =========================
            // MENU BARIS 2
            // =========================
            Row(
              children: [
                Expanded(
                  child: MenuCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Pemeriksaan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PemeriksaanPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: MenuCard(
                    icon: Icons.vaccines_outlined,
                    title: 'Imunisasi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImunisasiPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // =========================
            // JADWAL POSYANDU
            // =========================
            const Text(
              'Jadwal Posyandu',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // KARTU JADWAL
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JadwalPage()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.green,
                      size: 35,
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Posyandu Bulan Oktober',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          SizedBox(height: 5),

                          Text(
                            '12 Oktober 2026 • 08.00 WIB',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // =========================
      // BOTTOM NAVIGATION
      // =========================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,

        onTap: (index) {
          // RIWAYAT
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RiwayatPage()),
            );
          }

          // PROFIL
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilPage()),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
