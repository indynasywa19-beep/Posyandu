import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pastikan class model Pemeriksaan sesuai dengan struktur proyek Kakak
class Pemeriksaan {
  final String? id;
  final String anakId;
  final String tanggal;
  final double beratBadan;
  final double tinggiBadan;
  final String catatan;

  Pemeriksaan({
    this.id,
    required this.anakId,
    required this.tanggal,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.catatan,
  });

  factory Pemeriksaan.fromMap(Map<String, dynamic> map) {
    return Pemeriksaan(
      id: map['id']?.toString(),
      anakId: map['anak_id']?.toString() ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      beratBadan: double.tryParse(map['berat_badan']?.toString() ?? '0') ?? 0,
      tinggiBadan: double.tryParse(map['tinggi_badan']?.toString() ?? '0') ?? 0,
      catatan: map['catatan']?.toString() ?? '',
    );
  }
}

class PemeriksaanPage extends StatefulWidget {
  const PemeriksaanPage({super.key});

  @override
  State<PemeriksaanPage> createState() => _PemeriksaanPageState();
}

class _PemeriksaanPageState extends State<PemeriksaanPage> {
  List<dynamic> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];
  String? selectedAnak;
  bool _isLoading = false;

  final tanggalController = TextEditingController();
  final beratController = TextEditingController();
  final tinggiController = TextEditingController();
  final catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    tanggalController.dispose();
    beratController.dispose();
    textControllersDispose();
    super.dispose();
  }

  void textControllersDispose() {
    beratController.dispose();
    tinggiController.dispose();
    catatanController.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final supabase = Supabase.instance.client;

      // Ambil daftar anak untuk dropdown
      final anakResponse = await supabase.from('anak').select();

      // Ambil daftar riwayat pemeriksaan
      final periksaResponse = await supabase
          .from('pemeriksaan')
          .select()
          .order('tanggal', ascending: false);

      setState(() {
        dataAnak = anakResponse as List<dynamic>;
        dataPemeriksaan = (periksaResponse as List<dynamic>)
            .map((item) => Pemeriksaan.fromMap(item as Map<String, dynamic>))
            .toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String namaAnak(String anakId) {
    final anak = dataAnak.firstWhere(
      (item) => item['id'].toString() == anakId,
      orElse: () => {'nama': 'Tidak Diketahui'},
    );
    return anak['nama'] ?? 'Tidak Diketahui';
  }

  void tampilkanForm({Pemeriksaan? pemeriksaan}) {
    if (pemeriksaan != null) {
      selectedAnak = pemeriksaan.anakId;
      tanggalController.text = pemeriksaan.tanggal;
      beratController.text = pemeriksaan.beratBadan.toString();
      tinggiController.text = pemeriksaan.tinggiBadan.toString();
      catatanController.text = pemeriksaan.catatan;
    } else {
      selectedAnak = dataAnak.isNotEmpty ? dataAnak[0]['id'].toString() : null;
      tanggalController.text = "";
      beratController.text = "";
      tinggiController.text = "";
      catatanController.text = "";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
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
                    DropdownButtonFormField<String>(
                      value: selectedAnak,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Anak',
                      ),
                      items: dataAnak.map<DropdownMenuItem<String>>((anak) {
                        return DropdownMenuItem<String>(
                          value: anak['id'].toString(),
                          child: Text(anak['nama'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAnak = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: tanggalController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pemeriksaan',
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'Pilih Tanggal',
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          String formattedDate =
                              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          setState(() {
                            tanggalController.text = formattedDate;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: beratController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Berat Badan (kg)',
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: tinggiController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tinggi Badan (cm)',
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: catatanController,
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tanggalController.text.isEmpty ||
                        beratController.text.isEmpty ||
                        tinggiController.text.isEmpty ||
                        selectedAnak == null) {
                      return;
                    }

                    String rawTanggal = tanggalController.text.trim();
                    String finalDateForSupabase = rawTanggal;

                    try {
                      if (!rawTanggal.contains('-')) {
                        List<String> parts = rawTanggal.split(' ');
                        if (parts.length == 3) {
                          String hari = parts[0].padLeft(2, '0');
                          String bulanTeks = parts[1].toLowerCase();
                          String tahun = parts[2];

                          Map<String, String> bulanMap = {
                            'januari': '01',
                            'februari': '02',
                            'maret': '03',
                            'april': '04',
                            'mei': '05',
                            'juni': '06',
                            'juli': '07',
                            'agustus': '08',
                            'september': '09',
                            'oktober': '10',
                            'november': '11',
                            'desember': '12',
                          };

                          String bulanAngka = bulanMap[bulanTeks] ?? '10';
                          finalDateForSupabase = "$tahun-$bulanAngka-$hari";
                        }
                      }
                    } catch (_) {
                      finalDateForSupabase =
                          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                    }

                    final mapData = {
                      'anak_id': selectedAnak,
                      'tanggal': finalDateForSupabase,
                      'berat_badan': double.tryParse(beratController.text) ?? 0,
                      'tinggi_badan':
                          double.tryParse(tinggiController.text) ?? 0,
                      'catatan': catatanController.text,
                    };

                    try {
                      if (pemeriksaan == null) {
                        await Supabase.instance.client
                            .from('pemeriksaan')
                            .insert(mapData);
                      } else {
                        await Supabase.instance.client
                            .from('pemeriksaan')
                            .update(mapData)
                            .eq('id', pemeriksaan.id!);
                      }
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menyimpan: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (!context.mounted) return;
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('pemeriksaan')
                      .delete()
                      .eq('id', pemeriksaan.id!);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await loadData();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus data: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
                onPressed: dataAnak.isEmpty ? null : () => tampilkanForm(),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : dataPemeriksaan.isEmpty
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
                                'BB: ${pemeriksaan.beratBadan} kg • TB: ${pemeriksaan.tinggiBadan} cm\n'
                                'Catatan: ${pemeriksaan.catatan.isEmpty ? "Tidak ada catatan" : pemeriksaan.catatan}',
                              ),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'edit')
                                  tampilkanForm(pemeriksaan: pemeriksaan);
                                if (value == 'hapus') hapusData(pemeriksaan);
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
