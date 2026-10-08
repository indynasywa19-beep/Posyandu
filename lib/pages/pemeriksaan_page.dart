import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/anak.dart';
import '../models/pemeriksaan.dart';

class PemeriksaanPage extends StatefulWidget {
  const PemeriksaanPage({super.key});

  @override
  State<PemeriksaanPage> createState() => _PemeriksaanPageState();
}

class _PemeriksaanPageState extends State<PemeriksaanPage> {
  List<Anak> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];

  int? anakTerpilih;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // =========================
  // LOAD DATA
  // =========================

  Future<void> loadData() async {
    final dataAnakDb = await DatabaseHelper.instance.getAllAnak();

    final dataPemeriksaanDb = await DatabaseHelper.instance.getAllPemeriksaan();

    setState(() {
      dataAnak = dataAnakDb.map((item) => Anak.fromMap(item)).toList();

      dataPemeriksaan = dataPemeriksaanDb
          .map((item) => Pemeriksaan.fromMap(item))
          .toList();
    });
  }

  // =========================
  // NAMA ANAK
  // =========================

  String namaAnak(int anakId) {
    final anak = dataAnak.firstWhere(
      (item) => item.id == anakId,
      orElse: () => Anak(
        id: 0,
        nama: 'Anak tidak ditemukan',
        nik: '',
        tanggalLahir: '',
        jenisKelamin: '',
      ),
    );

    return anak.nama;
  }

  // =========================
  // FORM
  // =========================

  void tampilkanForm({Pemeriksaan? pemeriksaan}) {
    if (dataAnak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan data anak terlebih dahulu.')),
      );

      return;
    }

    int selectedAnak = pemeriksaan?.anakId ?? dataAnak.first.id!;

    final tanggalController = TextEditingController(
      text: pemeriksaan?.tanggal ?? '',
    );

    final beratController = TextEditingController(
      text: pemeriksaan == null ? '' : pemeriksaan.beratBadan.toString(),
    );

    final tinggiController = TextEditingController(
      text: pemeriksaan == null ? '' : pemeriksaan.tinggiBadan.toString(),
    );

    final catatanController = TextEditingController(
      text: pemeriksaan?.catatan ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                pemeriksaan == null ? 'Tambah Pemeriksaan' : 'Edit Pemeriksaan',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedAnak,

                      decoration: const InputDecoration(
                        labelText: 'Pilih Anak',
                        prefixIcon: Icon(Icons.child_care),
                      ),

                      items: dataAnak.map((anak) {
                        return DropdownMenuItem<int>(
                          value: anak.id,
                          child: Text(anak.nama),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setDialogState(() {
                          selectedAnak = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: tanggalController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pemeriksaan',
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'Contoh: 12 Oktober 2026',
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: beratController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Berat Badan (kg)',
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: tinggiController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tinggi Badan (cm)',
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: catatanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (tanggalController.text.isEmpty ||
                        beratController.text.isEmpty ||
                        tinggiController.text.isEmpty) {
                      return;
                    }

                    final data = Pemeriksaan(
                      id: pemeriksaan?.id,
                      anakId: selectedAnak,
                      tanggal: tanggalController.text,
                      beratBadan: double.tryParse(beratController.text) ?? 0,
                      tinggiBadan: double.tryParse(tinggiController.text) ?? 0,
                      catatan: catatanController.text,
                    );

                    if (pemeriksaan == null) {
                      await DatabaseHelper.instance.insertPemeriksaan(
                        data.toMap(),
                      );
                    } else {
                      await DatabaseHelper.instance.updatePemeriksaan(
                        pemeriksaan.id!,
                        data.toMap(),
                      );
                    }

                    if (!mounted) return;

                    Navigator.pop(context);

                    await loadData();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),

                  child: Text(pemeriksaan == null ? 'Simpan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================
  // HAPUS
  // =========================

  void hapusData(Pemeriksaan pemeriksaan) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Pemeriksaan'),

          content: const Text(
            'Apakah kamu yakin ingin menghapus data pemeriksaan ini?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),

            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.deletePemeriksaan(
                  pemeriksaan.id!,
                );

                if (!mounted) return;

                Navigator.pop(context);

                await loadData();
              },

              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),

      appBar: AppBar(
        title: const Text('Pemeriksaan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Riwayat Pemeriksaan',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              'Catatan pemeriksaan kesehatan anak.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: () {
                  tampilkanForm();
                },

                icon: const Icon(Icons.add),

                label: const Text('Tambah Pemeriksaan'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: dataPemeriksaan.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada data pemeriksaan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: dataPemeriksaan.length,

                      itemBuilder: (context, index) {
                        final pemeriksaan = dataPemeriksaan[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),

                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),

                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE0F2E5),

                              child: Icon(
                                Icons.medical_services_outlined,
                                color: Colors.green,
                              ),
                            ),

                            title: Text(
                              namaAnak(pemeriksaan.anakId),

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),

                              child: Text(
                                '${pemeriksaan.tanggal}\n'
                                'BB: ${pemeriksaan.beratBadan} kg • '
                                'TB: ${pemeriksaan.tinggiBadan} cm\n'
                                '${pemeriksaan.catatan.isEmpty ? "Tidak ada catatan" : pemeriksaan.catatan}',
                              ),
                            ),

                            isThreeLine: true,

                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  tampilkanForm(pemeriksaan: pemeriksaan);
                                }

                                if (value == 'hapus') {
                                  hapusData(pemeriksaan);
                                }
                              },

                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'hapus',
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
