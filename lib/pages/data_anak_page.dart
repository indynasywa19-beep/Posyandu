import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/anak.dart';

class DataAnakPage extends StatefulWidget {
  const DataAnakPage({super.key});

  @override
  State<DataAnakPage> createState() => _DataAnakPageState();
}

class _DataAnakPageState extends State<DataAnakPage> {
  List<Anak> dataAnak = [];

  @override
  void initState() {
    super.initState();
    loadDataAnak();
  }

  // READ DATA DARI DATABASE
  Future<void> loadDataAnak() async {
    final data = await DatabaseHelper.instance.getAllAnak();

    setState(() {
      dataAnak = data.map((item) {
        return Anak.fromMap(item);
      }).toList();
    });
  }

  // FORM TAMBAH / EDIT
  void tampilkanForm({Anak? anak}) {
    final namaController = TextEditingController(text: anak?.nama ?? '');

    final nikController = TextEditingController(text: anak?.nik ?? '');

    final tanggalController = TextEditingController(
      text: anak?.tanggalLahir ?? '',
    );

    String jenisKelamin = anak?.jenisKelamin ?? 'Perempuan';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(anak == null ? 'Tambah Data Anak' : 'Edit Data Anak'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Anak',
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: nikController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'NIK',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: tanggalController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Lahir',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: jenisKelamin,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Perempuan',
                          child: Text('Perempuan'),
                        ),
                        DropdownMenuItem(
                          value: 'Laki-laki',
                          child: Text('Laki-laki'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          jenisKelamin = value!;
                        });
                      },
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
                    if (namaController.text.isEmpty ||
                        nikController.text.isEmpty ||
                        tanggalController.text.isEmpty) {
                      return;
                    }

                    final data = Anak(
                      id: anak?.id,
                      nama: namaController.text,
                      nik: nikController.text,
                      tanggalLahir: tanggalController.text,
                      jenisKelamin: jenisKelamin,
                    );

                    if (anak == null) {
                      // CREATE
                      await DatabaseHelper.instance.insertAnak(data.toMap());
                    } else {
                      // UPDATE
                      await DatabaseHelper.instance.updateAnak(
                        anak.id!,
                        data.toMap(),
                      );
                    }

                    if (!mounted) return;

                    Navigator.pop(context);

                    await loadDataAnak();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),

                  child: Text(anak == null ? 'Simpan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // DELETE
  void hapusData(Anak anak) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Data'),

          content: Text('Apakah kamu yakin ingin menghapus data ${anak.nama}?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),

            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.deleteAnak(anak.id!);

                if (!mounted) return;

                Navigator.pop(context);

                await loadDataAnak();
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
        title: const Text('Data Anak'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Data Anak',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              'Kelola data anak yang terdaftar di Posyandu.',
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

                label: const Text('Tambah Data Anak'),

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
              child: dataAnak.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada data anak.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: dataAnak.length,

                      itemBuilder: (context, index) {
                        final anak = dataAnak[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),

                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),

                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE0F2E5),

                              child: Icon(
                                Icons.child_care,
                                color: Colors.green,
                              ),
                            ),

                            title: Text(
                              anak.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),

                              child: Text(
                                '${anak.jenisKelamin} • ${anak.tanggalLahir}\n'
                                'NIK: ${anak.nik}',
                              ),
                            ),

                            isThreeLine: true,

                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  tampilkanForm(anak: anak);
                                }

                                if (value == 'hapus') {
                                  hapusData(anak);
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
