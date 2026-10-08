import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/anak.dart';
import '../models/imunisasi.dart';

class ImunisasiPage extends StatefulWidget {
  const ImunisasiPage({super.key});

  @override
  State<ImunisasiPage> createState() => _ImunisasiPageState();
}

class _ImunisasiPageState extends State<ImunisasiPage> {
  List<Anak> dataAnak = [];
  List<Imunisasi> dataImunisasi = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final dataAnakDb = await DatabaseHelper.instance.getAllAnak();

      final dataImunisasiDb = await DatabaseHelper.instance.getAllImunisasi();

      final anakList = dataAnakDb.map((item) => Anak.fromMap(item)).toList();

      final imunisasiList = dataImunisasiDb
          .map((item) => Imunisasi.fromMap(item))
          .toList();

      if (!mounted) return;

      setState(() {
        dataAnak = anakList;
        dataImunisasi = imunisasiList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengambil data: $e')));
    }
  }

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

  void tampilkanForm({Imunisasi? imunisasi}) {
    if (dataAnak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data anak belum tersedia.')),
      );
      return;
    }

    int selectedAnak = imunisasi?.anakId ?? dataAnak.first.id!;

    final tanggalController = TextEditingController(
      text: imunisasi?.tanggal ?? '',
    );

    final keteranganController = TextEditingController(
      text: imunisasi?.keterangan ?? '',
    );

    String selectedVaksin = imunisasi?.namaVaksin ?? 'BCG';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                imunisasi == null ? 'Tambah Imunisasi' : 'Edit Imunisasi',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PILIH ANAK
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
                        if (value == null) return;

                        setDialogState(() {
                          selectedAnak = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // JENIS VAKSIN
                    DropdownButtonFormField<String>(
                      value: selectedVaksin,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Vaksin',
                        prefixIcon: Icon(Icons.vaccines_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BCG', child: Text('BCG')),
                        DropdownMenuItem(value: 'Polio', child: Text('Polio')),
                        DropdownMenuItem(value: 'DPT', child: Text('DPT')),
                        DropdownMenuItem(
                          value: 'Hepatitis B',
                          child: Text('Hepatitis B'),
                        ),
                        DropdownMenuItem(
                          value: 'Campak',
                          child: Text('Campak'),
                        ),
                        DropdownMenuItem(value: 'MR', child: Text('MR')),
                        DropdownMenuItem(value: 'PCV', child: Text('PCV')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedVaksin = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // TANGGAL
                    TextField(
                      controller: tanggalController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Imunisasi',
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'Contoh: 12 Oktober 2026',
                      ),
                    ),

                    const SizedBox(height: 15),

                    // KETERANGAN
                    TextField(
                      controller: keteranganController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
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
                    if (tanggalController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tanggal imunisasi wajib diisi.'),
                        ),
                      );
                      return;
                    }

                    final data = Imunisasi(
                      id: imunisasi?.id,
                      anakId: selectedAnak,
                      namaVaksin: selectedVaksin,
                      tanggal: tanggalController.text,
                      keterangan: keteranganController.text,
                    );

                    if (imunisasi == null) {
                      await DatabaseHelper.instance.insertImunisasi(
                        data.toMap(),
                      );
                    } else {
                      await DatabaseHelper.instance.updateImunisasi(
                        imunisasi.id!,
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
                  child: Text(imunisasi == null ? 'Simpan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void hapusData(Imunisasi imunisasi) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Imunisasi'),
          content: const Text(
            'Apakah kamu yakin ingin menghapus data imunisasi ini?',
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
                await DatabaseHelper.instance.deleteImunisasi(imunisasi.id!);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),

      appBar: AppBar(
        title: const Text('Imunisasi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Imunisasi',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Catatan vaksinasi dan imunisasi anak.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL TAMBAH
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        tampilkanForm();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Imunisasi'),
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

                  // DATA
                  Expanded(
                    child: dataImunisasi.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada data imunisasi.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: dataImunisasi.length,
                            itemBuilder: (context, index) {
                              final imunisasi = dataImunisasi[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),

                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE0F2E5),
                                    child: Icon(
                                      Icons.vaccines_outlined,
                                      color: Colors.green,
                                    ),
                                  ),

                                  title: Text(
                                    imunisasi.namaVaksin,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '${namaAnak(imunisasi.anakId)}\n'
                                      '${imunisasi.tanggal}\n'
                                      '${imunisasi.keterangan.isEmpty ? "Tidak ada keterangan" : imunisasi.keterangan}',
                                    ),
                                  ),

                                  isThreeLine: true,

                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        tampilkanForm(imunisasi: imunisasi);
                                      }

                                      if (value == 'hapus') {
                                        hapusData(imunisasi);
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
