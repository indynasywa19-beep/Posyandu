import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/anak.dart';
import '../models/pemeriksaan.dart';
import '../models/imunisasi.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<Anak> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];
  List<Imunisasi> dataImunisasi = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final anakDb = await DatabaseHelper.instance.getAllAnak();

    final pemeriksaanDb = await DatabaseHelper.instance.getAllPemeriksaan();

    final imunisasiDb = await DatabaseHelper.instance.getAllImunisasi();

    if (!mounted) return;

    setState(() {
      dataAnak = anakDb.map((item) => Anak.fromMap(item)).toList();

      dataPemeriksaan = pemeriksaanDb
          .map((item) => Pemeriksaan.fromMap(item))
          .toList();

      dataImunisasi = imunisasiDb
          .map((item) => Imunisasi.fromMap(item))
          .toList();
    });
  }

  String namaAnak(int anakId) {
    final anak = dataAnak.where((item) => item.id == anakId);

    if (anak.isEmpty) {
      return 'Anak tidak ditemukan';
    }

    return anak.first.nama;
  }

  @override
  Widget build(BuildContext context) {
    final totalRiwayat = dataPemeriksaan.length + dataImunisasi.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),

      appBar: AppBar(
        title: const Text('Riwayat'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: totalRiwayat == 0
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    'Belum ada riwayat.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Riwayat Aktivitas',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Riwayat pemeriksaan dan imunisasi anak.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // PEMERIKSAAN
                  // =========================
                  if (dataPemeriksaan.isNotEmpty) ...[
                    const Text(
                      'Pemeriksaan',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...dataPemeriksaan.map((pemeriksaan) {
                      return _buildRiwayatCard(
                        icon: Icons.medical_services_outlined,
                        title: 'Pemeriksaan',
                        anak: namaAnak(pemeriksaan.anakId),
                        tanggal: pemeriksaan.tanggal,
                        detail:
                            'BB: ${pemeriksaan.beratBadan} kg • '
                            'TB: ${pemeriksaan.tinggiBadan} cm',
                        catatan: pemeriksaan.catatan,
                      );
                    }),

                    const SizedBox(height: 20),
                  ],

                  // =========================
                  // IMUNISASI
                  // =========================
                  if (dataImunisasi.isNotEmpty) ...[
                    const Text(
                      'Imunisasi',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...dataImunisasi.map((imunisasi) {
                      return _buildRiwayatCard(
                        icon: Icons.vaccines_outlined,
                        title: imunisasi.namaVaksin,
                        anak: namaAnak(imunisasi.anakId),
                        tanggal: imunisasi.tanggal,
                        detail: 'Vaksin ${imunisasi.namaVaksin}',
                        catatan: imunisasi.keterangan,
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRiwayatCard({
    required IconData icon,
    required String title,
    required String anak,
    required String tanggal,
    required String detail,
    required String catatan,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

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
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E5),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: Colors.green),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  anak,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  tanggal,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 6),

                Text(detail, style: const TextStyle(fontSize: 14)),

                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    catatan,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
