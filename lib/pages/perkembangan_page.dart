import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/anak.dart';
import '../models/pemeriksaan.dart';

class PerkembanganPage extends StatefulWidget {
  const PerkembanganPage({super.key});

  @override
  State<PerkembanganPage> createState() => _PerkembanganPageState();
}

class _PerkembanganPageState extends State<PerkembanganPage> {
  List<Anak> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];

  int? selectedAnakId;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final dataAnakDb = await DatabaseHelper.instance.getAllAnak();
    final dataPemeriksaanDb = await DatabaseHelper.instance.getAllPemeriksaan();

    final anakList = dataAnakDb.map((item) => Anak.fromMap(item)).toList();

    final pemeriksaanList = dataPemeriksaanDb
        .map((item) => Pemeriksaan.fromMap(item))
        .toList();

    setState(() {
      dataAnak = anakList;
      dataPemeriksaan = pemeriksaanList;

      if (anakList.isNotEmpty) {
        selectedAnakId ??= anakList.first.id;
      }
    });
  }

  List<Pemeriksaan> get pemeriksaanAnak {
    if (selectedAnakId == null) {
      return [];
    }

    return dataPemeriksaan
        .where((item) => item.anakId == selectedAnakId)
        .toList();
  }

  Anak? get anakTerpilih {
    if (selectedAnakId == null) {
      return null;
    }

    for (final anak in dataAnak) {
      if (anak.id == selectedAnakId) {
        return anak;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final anak = anakTerpilih;
    final riwayat = pemeriksaanAnak;

    Pemeriksaan? pemeriksaanTerakhir;

    if (riwayat.isNotEmpty) {
      pemeriksaanTerakhir = riwayat.first;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),

      appBar: AppBar(
        title: const Text('Perkembangan Anak'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: dataAnak.isEmpty
          ? const Center(
              child: Text(
                'Belum ada data anak.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perkembangan Anak',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Pantau pertumbuhan berdasarkan hasil pemeriksaan.',
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // PILIH ANAK
                    DropdownButtonFormField<int>(
                      value: selectedAnakId,
                      decoration: InputDecoration(
                        labelText: 'Pilih Anak',
                        prefixIcon: const Icon(
                          Icons.child_care,
                          color: Colors.green,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: dataAnak.map((anak) {
                        return DropdownMenuItem<int>(
                          value: anak.id,
                          child: Text(anak.nama),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAnakId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // DATA ANAK
                    if (anak != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.child_care,
                                color: Colors.green,
                                size: 32,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    anak.nama,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '${anak.jenisKelamin} • ${anak.tanggalLahir}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    const Text(
                      'Hasil Terakhir',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (pemeriksaanTerakhir == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 45,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Belum ada hasil pemeriksaan.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.monitor_weight_outlined,
                              title: 'Berat Badan',
                              value: '${pemeriksaanTerakhir.beratBadan} kg',
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.height,
                              title: 'Tinggi Badan',
                              value: '${pemeriksaanTerakhir.tinggiBadan} cm',
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 25),

                    const Text(
                      'Riwayat Pertumbuhan',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (riwayat.isEmpty)
                      const Text(
                        'Belum ada riwayat pertumbuhan.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) {
                          final pemeriksaan = riwayat[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2E5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.show_chart,
                                    color: Colors.green,
                                  ),
                                ),

                                const SizedBox(width: 15),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pemeriksaan.tanggal,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        'BB: ${pemeriksaan.beratBadan} kg • '
                                        'TB: ${pemeriksaan.tinggiBadan} cm',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),

                                      if (pemeriksaan.catatan.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            pemeriksaan.catatan,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green, size: 32),

          const SizedBox(height: 10),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
