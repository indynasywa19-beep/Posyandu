import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_theme.dart';
import '../widgets/kader_widgets.dart';
import 'home_kader_page.dart';
import 'jadwal_page.dart';
import 'profil_page.dart';


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
  final bool openFormOnStart;

  const PemeriksaanPage({super.key, this.openFormOnStart = false});

  @override
  State<PemeriksaanPage> createState() => _PemeriksaanPageState();
}

class _PemeriksaanPageState extends State<PemeriksaanPage> {
  List<dynamic> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];
  bool _isLoading = false;
  bool _autoFormShown = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadData().then((_) {
      if (!widget.openFormOnStart || _autoFormShown || !mounted) return;
      _autoFormShown = true;
      if (dataAnak.isNotEmpty) {
        tampilkanForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data anak belum tersedia.')),
        );
      }
    });
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final supabase = Supabase.instance.client;

      final anakResponse = await supabase.from('anak').select().order('nama');
      final periksaResponse = await supabase
          .from('pemeriksaan')
          .select()
          .order('tanggal', ascending: false);

      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic>? getChildData(String anakId) {
    try {
      return dataAnak.firstWhere(
        (item) => item['id'].toString() == anakId,
        orElse: () => null,
      ) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  String namaAnak(String anakId) {
    final child = getChildData(anakId);
    return child != null ? (child['nama'] ?? 'Tidak Diketahui') : 'Tidak Diketahui';
  }

  void tampilkanForm({Pemeriksaan? pemeriksaan}) {
    if (dataAnak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data anak belum tersedia.')),
      );
      return;
    }

    String selectedChildId = pemeriksaan != null
        ? pemeriksaan.anakId
        : (dataAnak.isNotEmpty ? dataAnak.first['id'].toString() : '');

    DateTime selectedDate;
    if (pemeriksaan != null && pemeriksaan.tanggal.isNotEmpty) {
      selectedDate = DateTime.tryParse(pemeriksaan.tanggal) ?? DateTime.now();
    } else {
      selectedDate = DateTime.now();
    }

    double weight = pemeriksaan?.beratBadan ?? 10.0;
    if (weight <= 0) weight = 10.0;

    double height = pemeriksaan?.tinggiBadan ?? 75.0;
    if (height <= 0) height = 75.0;

    const noteChips = [
      'ASI eksklusif',
      'MP-ASI',
      'Nafsu makan baik',
      'Perlu PMT',
    ];

    String selectedChip = '';
    String customNote = '';
    if (pemeriksaan != null && pemeriksaan.catatan.isNotEmpty) {
      if (noteChips.contains(pemeriksaan.catatan)) {
        selectedChip = pemeriksaan.catatan;
      } else {
        customNote = pemeriksaan.catatan;
      }
    }

    final customNoteController = TextEditingController(text: customNote);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeChild = getChildData(selectedChildId);
            final childName = activeChild != null ? (activeChild['nama'] ?? 'Pilih Anak') : 'Pilih Anak';
            final childSub = activeChild != null ? 'NIK: ${activeChild['nik'] ?? '-'}' : 'Ketuk untuk memilih';

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header matching Image 2
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: Color(0xFF0F172A),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pemeriksaan == null ? 'Catat Gizi' : 'Ubah Catatan Gizi',
                                style: GoogleFonts.fredoka(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Timbang & ukur bulan ini',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Form content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pilih Anak section
                          Text(
                            'PILIH ANAK',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          KaderChildSelectorTile(
                            childName: childName,
                            subtitle: childSub,
                            onSelectChild: () async {
                              final pickedId = await showDialog<String>(
                                context: context,
                                builder: (dlgCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Text(
                                    'Pilih Anak',
                                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                                  ),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    height: 300,
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: dataAnak.length,
                                      separatorBuilder: (_, _) => const Divider(height: 1),
                                      itemBuilder: (_, idx) {
                                        final item = dataAnak[idx];
                                        final isSel = item['id'].toString() == selectedChildId;
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: isSel
                                                ? const Color(0xFF1D4ED8)
                                                : const Color(0xFFEFF6FF),
                                            child: Icon(
                                              Icons.child_care_rounded,
                                              color: isSel ? Colors.white : const Color(0xFF1D4ED8),
                                            ),
                                          ),
                                          title: Text(
                                            item['nama'] ?? '-',
                                            style: GoogleFonts.nunito(
                                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                              color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          subtitle: Text(
                                            'NIK: ${item['nik'] ?? '-'}',
                                            style: GoogleFonts.nunito(fontSize: 12),
                                          ),
                                          trailing: isSel
                                              ? const Icon(Icons.check_circle, color: Color(0xFF1D4ED8))
                                              : null,
                                          onTap: () => Navigator.pop(dlgCtx, item['id'].toString()),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                              if (pickedId != null) {
                                setModalState(() {
                                  selectedChildId = pickedId;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 18),

                          // Tanggal Pemeriksaan
                          Text(
                            'TANGGAL PEMERIKSAAN',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Material(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF1D4ED8),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Ubah',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Berat Badan stepper (Image 2 style)
                          KaderNumberStepper(
                            label: 'Berat Badan',
                            unit: 'kg',
                            subtitle: 'kilogram (boleh desimal)',
                            value: weight,
                            step: 0.1,
                            min: 0.5,
                            max: 100.0,
                            onChanged: (val) {
                              setModalState(() {
                                weight = val;
                              });
                            },
                          ),

                          const SizedBox(height: 18),

                          // Tinggi Badan stepper (Image 2 style)
                          KaderNumberStepper(
                            label: 'Tinggi Badan',
                            unit: 'cm',
                            subtitle: 'sentimeter',
                            value: height,
                            step: 0.5,
                            min: 20.0,
                            max: 200.0,
                            onChanged: (val) {
                              setModalState(() {
                                height = val;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // Catatan Gizi section
                          Text(
                            'CATATAN GIZI',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: noteChips.map((note) {
                              final isSel = selectedChip == note;
                              return ChoiceChip(
                                label: Text(note),
                                selected: isSel,
                                selectedColor: const Color(0xFF1D4ED8),
                                backgroundColor: const Color(0xFFEFF6FF),
                                labelStyle: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : const Color(0xFF1D4ED8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSel ? const Color(0xFF1D4ED8) : Colors.transparent,
                                  ),
                                ),
                                onSelected: (selected) {
                                  setModalState(() {
                                    selectedChip = selected ? note : '';
                                    if (selected) {
                                      customNoteController.text = '';
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),
                          TextField(
                            controller: customNoteController,
                            onChanged: (val) {
                              if (val.isNotEmpty && selectedChip.isNotEmpty) {
                                setModalState(() {
                                  selectedChip = '';
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Atau ketik catatan khusus...',
                              hintStyle: GoogleFonts.nunito(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Save Button
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (selectedChildId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Pilih anak terlebih dahulu.')),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSaving = true);

                                  final formattedDate =
                                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                                  final finalNote = selectedChip.isNotEmpty
                                      ? selectedChip
                                      : customNoteController.text.trim();

                                  final mapData = {
                                    'anak_id': selectedChildId,
                                    'tanggal': formattedDate,
                                    'berat_badan': weight,
                                    'tinggi_badan': height,
                                    'catatan': finalNote,
                                  };

                                  try {
                                    final supabase = Supabase.instance.client;
                                    if (pemeriksaan == null) {
                                      await supabase.from('pemeriksaan').insert(mapData);
                                    } else {
                                      await supabase
                                          .from('pemeriksaan')
                                          .update(mapData)
                                          .eq('id', pemeriksaan.id!);
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    await loadData();
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    setModalState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan: $error'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  pemeriksaan == null ? 'Simpan catatan' : 'Simpan perubahan',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Hapus Pemeriksaan',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Apakah kamu yakin ingin menghapus data pemeriksaan ${namaAnak(pemeriksaan.anakId)}?',
            style: GoogleFonts.nunito(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
              child: Text(
                'Hapus',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onNavigationTap(BuildContext context, int index) {
    // KaderBottomAppBar: 0=Beranda, 1=Anak, [FAB=CatatGizi], 2=Jadwal, 3=Profil
    final page = switch (index) {
      0 => const HomeKaderPage(),
      1 => const JadwalPage(isKader: true),
      2 => const JadwalPage(isKader: true),
      3 => const ProfilPage(),
      _ => null,
    };
    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = dataPemeriksaan.where((p) {
      if (_searchQuery.isEmpty) return true;
      final name = namaAnak(p.anakId).toLowerCase();
      final note = p.catatan.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || note.contains(q);
    }).toList();

    return Theme(
      data: AppTheme.kader,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: KaderTopBar(
                  title: 'Catat Gizi',
                  subtitle: 'Timbang & ukur pertumbuhan anak',
                  onBack: () => Navigator.maybePop(context),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF1D4ED8),
                        size: 24,
                      ),
                      tooltip: 'Tambah Catatan',
                      onPressed: () => tampilkanForm(),
                    ),
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: KaderSearchBar(
                  hintText: 'Cari nama anak atau catatan...',
                  onTap: () async {
                    final query = await showDialog<String>(
                      context: context,
                      builder: (ctx) {
                        final c = TextEditingController(text: _searchQuery);
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Cari Data Gizi',
                            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                          ),
                          content: TextField(
                            controller: c,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Ketik nama anak...',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                          actions: [
                            if (_searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, ''),
                                child: const Text('Reset'),
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, c.text),
                              child: const Text('Terapkan'),
                            ),
                          ],
                        );
                      },
                    );
                    if (query != null) {
                      setState(() {
                        _searchQuery = query;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Total count info pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: KaderInfoPill(
                  icon: Icons.monitor_weight_outlined,
                  message: '${dataPemeriksaan.length} total riwayat pengukuran gizi',
                ),
              ),

              const SizedBox(height: 12),

              // List of records
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.monitor_weight_outlined,
                                      color: Color(0xFF1D4ED8),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada data cocok "$_searchQuery"'
                                        : 'Belum ada catatan gizi',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ketuk tombol + untuk mulai mencatat pertumbuhan anak',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, i) => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: KaderDashedDivider(),
                            ),
                            itemBuilder: (context, index) {
                              final p = filteredList[index];
                              final child = getChildData(p.anakId);
                              final cName = child != null ? (child['nama'] ?? 'Anak') : 'Anak';

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Child avatar
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFEDD5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.face_rounded,
                                        color: Color(0xFFEA580C),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  cName,
                                                  style: GoogleFonts.fredoka(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              // Date badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  p.tanggal,
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF1D4ED8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Measurement tags
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.scale_rounded, size: 14, color: Color(0xFF475569)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${p.beratBadan} kg',
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF334155),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.height_rounded, size: 14, color: Color(0xFF475569)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${p.tinggiBadan} cm',
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF334155),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          if (p.catatan.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p.catatan,
                                                style: GoogleFonts.nunito(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFFB45309),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Action buttons
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Color(0xFF64748B),
                                      ),
                                      onPressed: () => tampilkanForm(pemeriksaan: p),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Color(0xFFEF4444),
                                      ),
                                      onPressed: () => hapusData(p),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: KaderCenterFab(
          onPressed: () => tampilkanForm(),
        ),
        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: -1,
          onTabSelected: (index) => _onNavigationTap(context, index),
        ),
      ),
    );
  }
}
