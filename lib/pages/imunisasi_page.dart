import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anak.dart';
import '../models/imunisasi.dart';
import '../widgets/app_theme.dart';
import '../widgets/kader_widgets.dart';
import 'home_kader_page.dart';
import 'jadwal_page.dart';
import 'profil_page.dart';


class ImunisasiPage extends StatefulWidget {
  final bool openFormOnStart;

  const ImunisasiPage({super.key, this.openFormOnStart = false});

  @override
  State<ImunisasiPage> createState() => _ImunisasiPageState();
}

class _ImunisasiPageState extends State<ImunisasiPage> {
  List<Anak> dataAnak = [];
  List<Imunisasi> dataImunisasi = [];
  bool isLoading = true;
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
    try {
      final supabase = Supabase.instance.client;
      final dataAnakRows = await supabase.from('anak').select().order('nama');
      final dataImunisasiRows = await supabase
          .from('imunisasi')
          .select()
          .order('tanggal', ascending: false);

      final anakList = dataAnakRows.map((item) => Anak.fromMap(item)).toList();
      final imunisasiList = dataImunisasiRows
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  Anak? getChild(Object anakId) {
    try {
      return dataAnak.firstWhere((item) => item.id == anakId);
    } catch (_) {
      return null;
    }
  }

  String namaAnak(Object anakId) {
    final anak = getChild(anakId);
    return anak != null ? anak.nama : 'Anak tidak ditemukan';
  }

  void tampilkanForm({Imunisasi? imunisasi}) {
    if (dataAnak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data anak belum tersedia.')),
      );
      return;
    }

    Object selectedAnakId = imunisasi?.anakId ?? dataAnak.first.id!;

    DateTime selectedDate;
    if (imunisasi != null && imunisasi.tanggal.isNotEmpty) {
      selectedDate = DateTime.tryParse(imunisasi.tanggal) ?? DateTime.now();
    } else {
      selectedDate = DateTime.now();
    }

    const vaccineChips = [
      'HB-0',
      'BCG',
      'Polio',
      'DPT-HB-Hib',
      'Campak',
      'Vitamin A',
      'PCV',
      'Rotavirus',
    ];

    String selectedVaksin = imunisasi?.namaVaksin ?? 'BCG';
    final customVaksinController = TextEditingController(
      text: vaccineChips.contains(selectedVaksin) ? '' : selectedVaksin,
    );

    final keteranganController = TextEditingController(
      text: imunisasi?.keterangan ?? '',
    );

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeChild = getChild(selectedAnakId);
            final childName = activeChild != null ? activeChild.nama : 'Pilih Anak';
            final childSub = activeChild != null
                ? 'NIK: ${activeChild.nik.isNotEmpty ? activeChild.nik : '-'}'
                : 'Ketuk untuk memilih';

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

                  // Header matching Image 4
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
                                imunisasi == null ? 'Input Imunisasi' : 'Ubah Imunisasi',
                                style: GoogleFonts.fredoka(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Catat vaksin & vitamin',
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
                          // Section: Pilih Anak
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
                              final picked = await showDialog<Object>(
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
                                        final child = dataAnak[idx];
                                        final isSel = child.id == selectedAnakId;
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
                                            child.nama,
                                            style: GoogleFonts.nunito(
                                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                              color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          subtitle: Text(
                                            'NIK: ${child.nik.isNotEmpty ? child.nik : '-'}',
                                            style: GoogleFonts.nunito(fontSize: 12),
                                          ),
                                          trailing: isSel
                                              ? const Icon(Icons.check_circle, color: Color(0xFF1D4ED8))
                                              : null,
                                          onTap: () => Navigator.pop(dlgCtx, child.id),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedAnakId = picked;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 20),

                          // Section: Jenis Imunisasi (Image 4 chips)
                          Text(
                            'JENIS IMUNISASI',
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
                            children: vaccineChips.map((vaksin) {
                              final isSel = selectedVaksin == vaksin;
                              return ChoiceChip(
                                label: Text(vaksin),
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
                                    if (selected) {
                                      selectedVaksin = vaksin;
                                      customVaksinController.text = '';
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),
                          TextField(
                            controller: customVaksinController,
                            onChanged: (val) {
                              if (val.trim().isNotEmpty) {
                                setModalState(() {
                                  selectedVaksin = val.trim();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Atau ketik jenis vaksin lain...',
                              hintStyle: GoogleFonts.nunito(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(Icons.vaccines_outlined, color: Color(0xFF64748B)),
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

                          const SizedBox(height: 20),

                          // Section: Tanggal Pemberian
                          Text(
                            'TANGGAL PEMBERIAN',
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
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(now.year + 5),
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

                          const SizedBox(height: 20),

                          // Section: Catatan (Opsional)
                          Text(
                            'CATATAN (OPSIONAL)',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: keteranganController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Reaksi, dosis, dll.',
                              hintStyle: GoogleFonts.nunito(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                              ),
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
                                  final vaccineName = customVaksinController.text.trim().isNotEmpty
                                      ? customVaksinController.text.trim()
                                      : selectedVaksin;

                                  if (vaccineName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Pilih atau ketik jenis vaksin.')),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSaving = true);

                                  final formattedDate =
                                      '${selectedDate.year.toString().padLeft(4, '0')}-'
                                      '${selectedDate.month.toString().padLeft(2, '0')}-'
                                      '${selectedDate.day.toString().padLeft(2, '0')}';

                                  final data = Imunisasi(
                                    id: imunisasi?.id,
                                    anakId: selectedAnakId,
                                    namaVaksin: vaccineName,
                                    tanggal: formattedDate,
                                    keterangan: keteranganController.text.trim(),
                                  );

                                  try {
                                    final supabase = Supabase.instance.client;
                                    if (imunisasi == null) {
                                      await supabase.from('imunisasi').insert(data.toMap());
                                    } else {
                                      await supabase
                                          .from('imunisasi')
                                          .update(data.toMap())
                                          .eq('id', imunisasi.id!);
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    await loadData();
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    setModalState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan imunisasi: $error'),
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
                                  imunisasi == null ? 'Simpan imunisasi' : 'Simpan perubahan',
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

  void hapusData(Imunisasi imunisasi) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Hapus Imunisasi',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Apakah kamu yakin ingin menghapus data imunisasi ${imunisasi.namaVaksin} untuk ${namaAnak(imunisasi.anakId)}?',
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
                      .from('imunisasi')
                      .delete()
                      .eq('id', imunisasi.id!);
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
    if (index == -1) return; // center FAB tapped through nav
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
    final filteredList = dataImunisasi.where((item) {
      if (_searchQuery.isEmpty) return true;
      final childName = namaAnak(item.anakId).toLowerCase();
      final vaccine = item.namaVaksin.toLowerCase();
      final note = item.keterangan.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return childName.contains(q) || vaccine.contains(q) || note.contains(q);
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
                  title: 'Input Imunisasi',
                  subtitle: 'Catat vaksin & vitamin anak',
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
                      tooltip: 'Tambah Imunisasi',
                      onPressed: () => tampilkanForm(),
                    ),
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: KaderSearchBar(
                  hintText: 'Cari nama anak atau jenis vaksin...',
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
                            'Cari Data Imunisasi',
                            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
                          ),
                          content: TextField(
                            controller: c,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Ketik nama anak atau vaksin...',
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
                  icon: Icons.vaccines_outlined,
                  message: '${dataImunisasi.length} total riwayat imunisasi tercatat',
                ),
              ),

              const SizedBox(height: 12),

              // List of records
              Expanded(
                child: isLoading
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
                                      Icons.vaccines_outlined,
                                      color: Color(0xFF1D4ED8),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada data cocok "$_searchQuery"'
                                        : 'Belum ada data imunisasi',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ketuk tombol + untuk mulai mencatat vaksinasi balita',
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
                              final item = filteredList[index];
                              final cName = namaAnak(item.anakId);

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Syringe/Vaccine icon badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.vaccines_rounded,
                                        color: Color(0xFF1D4ED8),
                                        size: 24,
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
                                                  item.namaVaksin,
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
                                                  item.tanggal,
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF1D4ED8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // Child name tag
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.child_care_rounded,
                                                size: 14,
                                                color: Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  cName,
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF334155),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          if (item.keterangan.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.keterangan,
                                                style: GoogleFonts.nunito(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF475569),
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
                                      onPressed: () => tampilkanForm(imunisasi: item),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Color(0xFFEF4444),
                                      ),
                                      onPressed: () => hapusData(item),
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
