import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anak.dart';
import '../models/pemeriksaan.dart';
import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/child_picker.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'data_anak_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

class PerkembanganPage extends StatefulWidget {
  final bool isKader;
  final Object? anakId;

  const PerkembanganPage({super.key, this.isKader = false, this.anakId});

  @override
  State<PerkembanganPage> createState() => _PerkembanganPageState();
}

class _PerkembanganPageState extends State<PerkembanganPage> {
  static const _metricWeight = 'BB/U';
  static const _metricHeight = 'TB/U';
  static const _metricKms = 'KMS';

  List<Anak> dataAnak = [];
  List<Pemeriksaan> dataPemeriksaan = [];

  Object? selectedAnakId;
  String selectedMetric = _metricWeight;

  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
  Future<void> loadData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (!widget.isKader && user == null) {
      if (!mounted) return;

      setState(() {
        loadError = 'Sesi login tidak ditemukan. Silakan masuk kembali.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final List childrenRows;

      if (widget.isKader) {
        childrenRows = await supabase.from('anak').select().order('nama');
      } else {
        childrenRows = await supabase
            .from('anak')
            .select()
            .eq('user_id', user!.id)
            .order('nama');
      }

      final childList = childrenRows
          .whereType()
          .map((row) => Anak.fromMap(row))
          .toList();

      final childIds = childList
          .map((child) => child.id)
          .where((id) => id != null && id.toString().trim().isNotEmpty)
          .cast<Object>()
          .toList();

      final List examinationRows;

      if (childIds.isEmpty) {
        examinationRows = [];
      } else {
        examinationRows = await supabase
            .from('pemeriksaan')
            .select()
            .inFilter('anak_id', childIds);
      }

      final examinations = examinationRows
          .whereType()
          .map((row) => Pemeriksaan.fromMap(row))
          .toList();

      examinations.sort((a, b) {
        final dateA = DateTime.tryParse(a.tanggal);
        final dateB = DateTime.tryParse(b.tanggal);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return -1;
        if (dateB == null) return 1;

        return dateA.compareTo(dateB);
      });

      if (!mounted) return;

      Object? nextSelectedId;
      if (childList.isNotEmpty) {
        if (widget.anakId != null) {
          for (final child in childList) {
            if (child.id?.toString() == widget.anakId.toString()) {
              nextSelectedId = child.id;
              break;
            }
          }
        }
        if (nextSelectedId == null && selectedAnakId != null) {
          for (final child in childList) {
            if (child.id?.toString() == selectedAnakId.toString()) {
              nextSelectedId = child.id;
              break;
            }
          }
        }
        nextSelectedId ??= childList[0].id;
      }

      setState(() {
        dataAnak = childList;
        dataPemeriksaan = examinations;
        selectedAnakId = nextSelectedId;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadError = friendlyError(
          error,
          fallback:
              'Data perkembangan belum bisa dimuat. Coba lagi sebentar lagi.',
        );
        isLoading = false;
      });
    }
  }

  List<Pemeriksaan> get pemeriksaanAnak {
    if (selectedAnakId == null) return [];

    return dataPemeriksaan
        .where((item) => item.anakId.toString() == selectedAnakId.toString())
        .toList();
  }

  Anak? get anakTerpilih {
    if (selectedAnakId == null) return null;
    for (final anak in dataAnak) {
      if (anak.id?.toString() == selectedAnakId.toString()) return anak;
    }

    return dataAnak.isEmpty ? null : dataAnak[0];
  }

  Pemeriksaan? get pemeriksaanTerakhir {
    final riwayat = pemeriksaanAnak;
    return riwayat.isEmpty ? null : riwayat[riwayat.length - 1];
  }

  Pemeriksaan? get pemeriksaanSebelumnya {
    final riwayat = pemeriksaanAnak;
    return riwayat.length < 2 ? null : riwayat[riwayat.length - 2];
  }

  double? get perubahanBerat {
    final terbaru = pemeriksaanTerakhir;
    final sebelumnya = pemeriksaanSebelumnya;

    if (terbaru == null || sebelumnya == null) return null;

    return terbaru.beratBadan - sebelumnya.beratBadan;
  }

  double? get perubahanTinggi {
    final terbaru = pemeriksaanTerakhir;
    final sebelumnya = pemeriksaanSebelumnya;

    if (terbaru == null || sebelumnya == null) return null;

    return terbaru.tinggiBadan - sebelumnya.tinggiBadan;
  }

  ({String code, String label, Color bg, Color fg}) _kmsStatus(
    double? deltaWeight,
  ) {
    if (deltaWeight == null) {
      return (
        code: 'B',
        label: 'B · Baru ditimbang',
        bg: const Color(0xFFEFF6FF),
        fg: AppColors.navy,
      );
    }
    if (deltaWeight > 0) {
      return (
        code: 'N',
        label: 'N · Naik',
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF15803D),
      );
    }
    return (
      code: 'T',
      label: 'T · Tidak naik',
      bg: const Color(0xFFFEF3C7),
      fg: const Color(0xFFB45309),
    );
  }

  int? _ageInMonths(String? birthIso, String? examIso) {
    if (birthIso == null || birthIso.isEmpty) return null;
    final birth = DateTime.tryParse(birthIso);
    final ref = examIso != null ? DateTime.tryParse(examIso) : DateTime.now();
    if (birth == null || ref == null) return null;

    final months = (ref.year - birth.year) * 12 + (ref.month - birth.month);
    return months < 0 ? 0 : months;
  }

  String _autoRecommendation(Anak? anak, Pemeriksaan terbaru, double? deltaBb) {
    final ageMonths = _ageInMonths(anak?.tanggalLahir, terbaru.tanggal);
    final isNotRising = deltaBb != null && deltaBb <= 0;

    if (isNotRising) {
      return 'Berat badan tidak naik dari pemeriksaan sebelumnya (Status T). '
          'Tingkatkan frekuensi makan, tambahkan sumber protein hewani (telur, ikan, ayam/hati), '
          'dan konsultasikan dengan Kader atau Bidan Posyandu.';
    }

    if (ageMonths != null) {
      if (ageMonths < 6) {
        return 'Usia $ageMonths bulan: Lanjutkan pemberian ASI eksklusif tanpa tambahan makanan/minuman lain dan pantau kenaikan berat badan tiap bulan.';
      }
      if (ageMonths <= 8) {
        return 'Usia $ageMonths bulan: Berikan MPASI tekstur lumat/halus 2–3 kali sehari disertai protein hewani serta tetap lanjutkan ASI.';
      }
      if (ageMonths <= 11) {
        return 'Usia $ageMonths bulan: Tingkatkan tekstur MPASI menjadi cincang halus/kasar 3–4 kali sehari dengan porsi seimbang dan camilan sehat.';
      }
      if (ageMonths <= 23) {
        return 'Usia $ageMonths bulan: Berikan makanan keluarga bergizi seimbang 3–4 kali sehari, lengkapi imunisasi lanjutan, dan lanjutkan ASI hingga 2 tahun.';
      }
      return 'Usia $ageMonths bulan: Pertahankan pola makan gizi seimbang 3 kali sehari, pastikan asupan protein dan sayur terpenuhi, serta rutin timbang tiap bulan.';
    }

    return 'Pertahankan pemantauan berat dan tinggi badan setiap bulan di Posyandu serta pastikan jadwal imunisasi dan vitamin A terpenuhi.';
  }

  String _formatAgeText(String? birthIso, [String? refIso]) {
    final months = _ageInMonths(birthIso, refIso);
    if (months == null) return '-';
    if (months < 12) return '$months bulan';
    final years = months ~/ 12;
    final remMonths = months % 12;
    if (remMonths == 0) return '$years tahun ($months bln)';
    return '$years thn $remMonths bln ($months bln)';
  }

  String formatPerubahan(double? nilai, String satuan) {
    if (nilai == null) return 'Belum ada pembanding';

    if (nilai > 0) {
      return 'Naik ${nilai.toStringAsFixed(1)} $satuan';
    }

    if (nilai < 0) {
      return 'Turun ${nilai.abs().toStringAsFixed(1)} $satuan';
    }

    return 'Tidak berubah';
  }

  IconData _arahPerubahan(double? nilai) {
    if (nilai == null) return Icons.horizontal_rule_rounded;
    if (nilai > 0) return Icons.trending_up_rounded;
    if (nilai < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  String formatTanggal(String tanggal) {
    final date = DateTime.tryParse(tanggal);

    if (date == null) return tanggal;

    return '${date.day} ${bulanSingkat(date.month)} ${date.year}';
  }

  String _tanggalLengkap(String tanggal) {
    final date = DateTime.tryParse(tanggal);

    return date == null ? tanggal : tanggalLengkap(date);
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI
  // ---------------------------------------------------------------------------
  void _onParentNavigationTap(BuildContext context, int index) {
    final Widget? page = switch (index) {
      0 => const HomeOrtuPage(),
      1 => const DataAnakPage(),
      2 => const JadwalPage(),
      3 => const RiwayatPage(),
      4 => const ProfilPage(),
      _ => null,
    };

    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk membuka SI-POSYANDU.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(
              error,
              fallback: 'Belum bisa keluar dari akun. Coba lagi.',
            ),
          ),
        ),
      );
    }
  }

  String _formatTanggal(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day} ${bulanSingkat(date.month)} ${date.year}';
  }

  Future<void> _pickChild() async {
    final id = await showChildPicker(
      context,
      children: dataAnak
          .map((a) => {'id': a.id, 'nama': a.nama, 'nik': a.nik})
          .toList(),
      selectedId: selectedAnakId?.toString(),
    );

    if (id == null || !mounted) return;

    for (final a in dataAnak) {
      if (a.id.toString() == id) {
        setState(() => selectedAnakId = a.id);
        break;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isKader = widget.isKader;

    if (isKader) {
      final isMobile = MediaQuery.sizeOf(context).width < 600;

      return KaderWebScaffold(
        activeIndex: 1,
        breadcrumb: 'Beranda / Monitoring Anak / KMS Digital',
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 8 : 24,
            isMobile ? 16 : 24,
            isMobile ? 8 : 24,
            8,
          ),
          child: _buildBody(),
        ),
      );
    }

    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppColors.navy,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Kembali',
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () => Navigator.maybePop(context),
                              ),
                              const Expanded(
                                child: Center(
                                  child: SiPosyanduBrand(
                                    textColor: Colors.white,
                                    govColor: Colors.white70,
                                    iconSize: 32,
                                  ),
                                ),
                              ),
                              LogoutButton(
                                inverted: true,
                                onPressed: _logout,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Kartu Menuju Sehat',
                            style: AppText.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KMS Digital',
                            style: AppText.headline.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildParentKmsContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 1,
          onTap: (index) => _onParentNavigationTap(context, index),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAMPILAN ORANG TUA
  // ---------------------------------------------------------------------------
  Widget _buildParentKmsContent() {
    final now = DateTime.now();

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingState(message: 'Memuat data perkembangan'),
      );
    }

    if (loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorState(
          title: 'Data perkembangan belum bisa dimuat',
          message: loadError!,
          onRetry: loadData,
        ),
      );
    }

    if (dataAnak.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.child_care_rounded,
          title: 'Belum ada data anak',
          message: 'Tambahkan data anak terlebih dahulu di menu Anak.',
        ),
      );
    }

    final anak = anakTerpilih;
    final riwayat = pemeriksaanAnak;
    final terbaru = pemeriksaanTerakhir;

    final childName = anak?.nama ?? '-';
    final childNik = anak != null && anak.nik.isNotEmpty ? anak.nik : '-';
    final childBirth = anak != null && anak.tanggalLahir.isNotEmpty
        ? '${_formatTanggal(anak.tanggalLahir)}\n(${_formatAgeText(anak.tanggalLahir)})'
        : '-';
    final childGender = anak != null && anak.jenisKelamin.isNotEmpty
        ? anak.jenisKelamin
        : '-';
    final childCountTotal = dataAnak.length;

    final isWeight = selectedMetric == _metricWeight;
    final statusKms = _kmsStatus(perubahanBerat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kartu Identitas Anak
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama anak',
                          style: AppText.caption.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          childName,
                          style: AppText.title.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tanggal lahir & usia',
                          style: AppText.caption.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          childBirth,
                          style: AppText.title.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NIK',
                          style: AppText.caption.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          childNik,
                          style: AppText.title.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Jenis kelamin',
                          style: AppText.caption.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          childGender,
                          style: AppText.title.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (childCountTotal > 1) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickChild,
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    '$childCountTotal anak terdaftar · Ganti anak',
                    style: AppText.caption.copyWith(
                      color: AppColors.logoGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Ringkasan Angka BB & TB Terakhir + Status N/T KMS
        if (terbaru != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hasil Pemeriksaan Terakhir',
                            style: AppText.subtitle.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTanggal(terbaru.tanggal),
                            style: AppText.caption.copyWith(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusKms.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusKms.label,
                        style: AppText.caption.copyWith(
                          color: statusKms.fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Berat Badan (BB)',
                              style: AppText.caption.copyWith(
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${terbaru.beratBadan.toStringAsFixed(1)} kg',
                              style: AppText.title.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatPerubahan(perubahanBerat, 'kg'),
                              style: AppText.caption.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tinggi Badan (TB)',
                              style: AppText.caption.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${terbaru.tinggiBadan.toStringAsFixed(1)} cm',
                              style: AppText.title.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatPerubahan(perubahanTinggi, 'cm'),
                              style: AppText.caption.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (terbaru.catatan.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Catatan Kader: ${terbaru.catatan.trim()}',
                      style: AppText.caption.copyWith(
                        color: AppColors.text,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        size: 18,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saran Tindak Lanjut',
                              style: AppText.caption.copyWith(
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _autoRecommendation(
                                anak,
                                terbaru,
                                perubahanBerat,
                              ),
                              style: AppText.caption.copyWith(
                                color: AppColors.text,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tab Switch BB/U dan TB/U
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedMetric = _metricWeight),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isWeight ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isWeight
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      'Berat Badan (BB/U)',
                      style: AppText.label.copyWith(
                        color: isWeight
                            ? AppColors.navy
                            : AppColors.secondaryText,
                        fontWeight: isWeight
                            ? FontWeight.w900
                            : FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedMetric = _metricHeight),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !isWeight ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !isWeight
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      'Tinggi Badan (TB/U)',
                      style: AppText.label.copyWith(
                        color: !isWeight
                            ? AppColors.navy
                            : AppColors.secondaryText,
                        fontWeight: !isWeight
                            ? FontWeight.w900
                            : FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Kartu Grafik KMS + Keterangan Lengkap
        _buildKmsChartCard(riwayat),
        const SizedBox(height: 16),

        // Keterangan Acuan
        Text(
          'Acuan: Standar Antropometri Anak Kementerian Kesehatan RI. Hasil bersifat informasi; konsultasikan dengan tenaga kesehatan.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(
            color: AppColors.secondaryText,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),

        // Footer dengan jarak lega
        Center(
          child: Text(
            '© ${now.year} SI-POSYANDU · Kebijakan Privasi · v1.0',
            style: AppText.caption.copyWith(
              color: AppColors.mutedText,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildKmsChartCard(List<Pemeriksaan> riwayat) {
    final isWeight = selectedMetric == _metricWeight;
    final satuan = isWeight ? 'kg' : 'cm';
    final judulGrafik = isWeight
        ? 'Grafik Perkembangan Berat Badan (BB/U)'
        : 'Grafik Perkembangan Tinggi Badan (TB/U)';
    final penjelasanGrafik = isWeight
        ? 'Memantau kenaikan berat badan anak setiap bulan. Garis hijau yang terus menanjak di dalam pita hijau menandakan pertumbuhan berat badan baik.'
        : 'Memantau pertambahan tinggi/panjang badan anak sesuai usia untuk mendeteksi dini risiko stunting.';

    String firstXLabel = '';
    String lastXLabel = '';
    if (riwayat.isNotEmpty) {
      final firstItem = riwayat[0];
      final lastItem = riwayat[riwayat.length - 1];
      final firstAgeMonths = _ageInMonths(
        anakTerpilih?.tanggalLahir,
        firstItem.tanggal,
      );
      final lastAgeMonths = _ageInMonths(
        anakTerpilih?.tanggalLahir,
        lastItem.tanggal,
      );
      firstXLabel = firstAgeMonths != null
          ? 'Usia $firstAgeMonths bln (${formatTanggal(firstItem.tanggal)})'
          : formatTanggal(firstItem.tanggal);
      lastXLabel = lastAgeMonths != null
          ? 'Usia $lastAgeMonths bln'
          : formatTanggal(lastItem.tanggal);
    }

    final values = riwayat
        .map((record) => isWeight ? record.beratBadan : record.tinggiBadan)
        .toList();
    final dates = riwayat.map((r) => DateTime.tryParse(r.tanggal)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            judulGrafik,
            style: AppText.subtitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            penjelasanGrafik,
            style: AppText.caption.copyWith(
              color: AppColors.secondaryText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          if (riwayat.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.show_chart_rounded,
                    size: 36,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada data penimbangan',
                    style: AppText.subtitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grafik pertumbuhan otomatis muncul setelah Kader menginput hasil pemeriksaan BB & TB anak.',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 230,
              width: double.infinity,
              child: CustomPaint(
                painter: _GrowthChartPainter(
                  values: values,
                  dates: dates,
                  lineColor: const Color(0xFF15803D),
                  gridColor: AppColors.divider,
                  labelStyle: AppText.caption,
                  firstLabel: firstXLabel,
                  lastLabel: lastXLabel,
                  isWeight: isWeight,
                  unit: satuan,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legenda Warna (Anti-Overflow dengan Wrap)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBF7D0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Jalur normal',
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Perlu perhatian',
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Grafik anak',
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: AppColors.divider),
            ),

            // Rincian Titik Pengukuran + Kode N / T / B + Usia Anak
            Text(
              'Rincian Pengukuran (${riwayat.length} kali)',
              style: AppText.label.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 8),
            for (int i = riwayat.length - 1; i >= 0; i--) ...[
              Builder(
                builder: (_) {
                  final item = riwayat[i];
                  final prev = i > 0 ? riwayat[i - 1] : null;
                  final deltaBb = prev == null
                      ? null
                      : item.beratBadan - prev.beratBadan;
                  final status = _kmsStatus(deltaBb);
                  final itemAge = _ageInMonths(
                    anakTerpilih?.tanggalLahir,
                    item.tanggal,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: status.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.code,
                            style: AppText.caption.copyWith(
                              color: status.fg,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            itemAge != null
                                ? '${formatTanggal(item.tanggal)} · Usia $itemAge bln'
                                : formatTanggal(item.tanggal),
                            style: AppText.caption.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                        Text(
                          isWeight
                              ? '${item.beratBadan.toStringAsFixed(1)} kg'
                              : '${item.tinggiBadan.toStringAsFixed(1)} cm',
                          style: AppText.label.copyWith(
                            color: AppColors.navy,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAMPILAN KADER
  // ---------------------------------------------------------------------------
  Widget _buildBody() {
    if (isLoading) {
      return const LoadingState(message: 'Memuat data perkembangan');
    }

    if (loadError != null) {
      return ErrorState(
        title: 'Data perkembangan belum bisa dimuat',
        message: loadError!,
        onRetry: loadData,
      );
    }

    if (dataAnak.isEmpty) {
      return const EmptyState(
        icon: Icons.child_care_rounded,
        title: 'Belum ada data anak',
        message: 'Tambahkan data anak terlebih dahulu di menu Anak.',
      );
    }

    final anak = anakTerpilih;
    final riwayat = pemeriksaanAnak;
    final riwayatTerbaru = riwayat.reversed.toList();
    final terbaru = pemeriksaanTerakhir;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.sm,
          AppSpace.page,
          AppSpace.xl + AppSpace.lg,
        ),
        children: [
          if (dataAnak.length > 1 && anak != null) ...[
            Text('Anak', style: AppText.label),
            const SizedBox(height: 6),
            KaderChildSelectorTile(
              childName: anak.nama,
              subtitle: 'NIK: ${anak.nik.isEmpty ? '-' : anak.nik}',
              onSelectChild: _pickChild,
            ),
            const SizedBox(height: AppSpace.lg),
          ],

          if (anak != null) _buildIdentityCard(anak, riwayat.length),
          const SizedBox(height: AppSpace.xl),

          // RINGKASAN
          SectionHeader(
            title: 'Ringkasan pertumbuhan',
            subtitle: terbaru == null
                ? 'Belum ada data pengukuran.'
                : 'Pemeriksaan terakhir: ${_tanggalLengkap(terbaru.tanggal)}',
          ),
          const SizedBox(height: AppSpace.md),
          if (terbaru == null)
            const _InfoPanel(
              icon: Icons.monitor_weight_outlined,
              title: 'Belum ada hasil pemeriksaan',
              message:
                  'Hasil pengukuran akan tampil setelah kader menyimpan pemeriksaan.',
            )
          else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Berat badan',
                      value: '${terbaru.beratBadan.toStringAsFixed(1)} kg',
                      changeIcon: _arahPerubahan(perubahanBerat),
                      changeText: formatPerubahan(perubahanBerat, 'kg'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.height_rounded,
                      title: 'Tinggi badan',
                      value: '${terbaru.tinggiBadan.toStringAsFixed(1)} cm',
                      changeIcon: _arahPerubahan(perubahanTinggi),
                      changeText: formatPerubahan(perubahanTinggi, 'cm'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Perubahan dihitung dari dua pemeriksaan terakhir. '
              'Kenaikan atau penurunan angka tidak otomatis menentukan '
              'status gizi anak.',
              style: AppText.caption,
            ),
          ],
          const SizedBox(height: AppSpace.xl),

          // GRAFIK
          const SectionHeader(
            title: 'Grafik pertumbuhan',
            subtitle:
                'Lihat perubahan hasil pengukuran berdasarkan riwayat pemeriksaan.',
          ),
          const SizedBox(height: AppSpace.md),
          ChoiceChipGroup(
            options: const [_metricWeight, _metricHeight, _metricKms],
            selected: selectedMetric,
            onChanged: (value) {
              if (value.isNotEmpty) setState(() => selectedMetric = value);
            },
          ),
          const SizedBox(height: AppSpace.md),
          if (selectedMetric == _metricKms)
            const _InfoPanel(
              icon: Icons.menu_book_outlined,
              title: 'Data KMS belum tersedia',
              message:
                  'Standar KMS belum terhubung dengan data pertumbuhan aplikasi.',
            )
          else if (riwayat.isEmpty)
            const _InfoPanel(
              icon: Icons.show_chart_rounded,
              title: 'Belum ada grafik',
              message:
                  'Grafik akan tampil setelah ada hasil pemeriksaan yang tersimpan.',
            )
          else
            _buildChart(riwayat),
          const SizedBox(height: AppSpace.md),
          const InlineMessage(
            status: AppStatus.info,
            message:
                'Grafik ini menampilkan riwayat pengukuran anak, '
                'bukan kurva standar pertumbuhan WHO. '
                'Penilaian status pertumbuhan memerlukan standar '
                'yang sesuai usia dan jenis kelamin.',
          ),
          const SizedBox(height: AppSpace.xl),

          // RIWAYAT
          SectionHeader(
            title: 'Riwayat pertumbuhan',
            subtitle: '${riwayat.length} data',
          ),
          const SizedBox(height: AppSpace.md),
          if (riwayat.isEmpty)
            const _InfoPanel(
              icon: Icons.history_rounded,
              title: 'Belum ada riwayat',
              message: 'Riwayat akan muncul setelah pemeriksaan disimpan.',
            )
          else
            for (var i = 0; i < riwayatTerbaru.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.md),
              _HistoryCard(
                dateText: _tanggalLengkap(riwayatTerbaru[i].tanggal),
                weight: '${riwayatTerbaru[i].beratBadan.toStringAsFixed(1)} kg',
                height: '${riwayatTerbaru[i].tinggiBadan.toStringAsFixed(1)} cm',
                note: riwayatTerbaru[i].catatan.trim(),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildIdentityCard(Anak anak, int jumlahPemeriksaan) {
    final gender = anak.jenisKelamin.trim().isEmpty ? '-' : anak.jenisKelamin;
    final birth = anak.tanggalLahir.trim().isEmpty
        ? '-'
        : '${_tanggalLengkap(anak.tanggalLahir)} (${_formatAgeText(anak.tanggalLahir)})';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: anak.nama, size: 52),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anak.nama, style: AppText.title),
                    const SizedBox(height: 2),
                    Text('$gender · Lahir $birth', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(),
          const SizedBox(height: AppSpace.md),
          _IdentityLine(
            icon: Icons.badge_outlined,
            label: 'NIK',
            value: anak.nik,
          ),
          const SizedBox(height: AppSpace.sm),
          _IdentityLine(
            icon: Icons.fact_check_outlined,
            label: 'Pemeriksaan',
            value: '$jumlahPemeriksaan tercatat',
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Pemeriksaan> riwayat) {
    return Builder(builder: (context) => _chartCard(context, riwayat));
  }

  Widget _chartCard(BuildContext context, List<Pemeriksaan> riwayat) {
    final isWeight = selectedMetric == _metricWeight;
    final satuan = isWeight ? 'kg' : 'cm';
    final judul = isWeight ? 'Berat badan' : 'Tinggi badan';

    final values = riwayat
        .map((record) => isWeight ? record.beratBadan : record.tinggiBadan)
        .toList();
    final dates = riwayat.map((r) => DateTime.tryParse(r.tanggal)).toList();

    final lowest = values.reduce(math.min);
    final highest = values.reduce(math.max);
    final lastText = '${values[values.length - 1].toStringAsFixed(1)} $satuan';

    final summary =
        'Grafik $judul. ${values.length} pengukuran. '
        'Terendah ${lowest.toStringAsFixed(1)} $satuan, '
        'tertinggi ${highest.toStringAsFixed(1)} $satuan. '
        'Terakhir $lastText pada ${_tanggalLengkap(riwayat[riwayat.length - 1].tanggal)}.';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: AppText.subtitle),
          const SizedBox(height: 2),
          Text(
            'Satuan: $satuan • ${values.length} pengukuran',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpace.lg),
          Semantics(
            label: summary,
            image: true,
            child: ExcludeSemantics(
              child: SizedBox(
                height: 230,
                width: double.infinity,
                child: CustomPaint(
                  painter: _GrowthChartPainter(
                    values: values,
                    dates: dates,
                    lineColor: Theme.of(context).colorScheme.primary,
                    gridColor: AppColors.divider,
                    labelStyle: AppText.caption,
                    firstLabel: formatTanggal(riwayat[0].tanggal),
                    lastLabel: formatTanggal(riwayat[riwayat.length - 1].tanggal),
                    isWeight: isWeight,
                    unit: satuan,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          if (riwayat.length >= 2)
            Text(
              'Terakhir: $lastText (${formatTanggal(riwayat[riwayat.length - 1].tanggal)})',
              style: AppText.label,
            )
          else
            Text(
              'Pengukuran pertama: ${values[0].toStringAsFixed(1)} $satuan',
              style: AppText.label,
            ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 9,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Titik menunjukkan hasil pengukuran yang tercatat. '
                  'Jarak antartitik mengikuti tanggal pemeriksaan.',
                  style: AppText.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// KOMPONEN HALAMAN
// =============================================================================
class _IdentityLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IdentityLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: AppSpace.sm),
        SizedBox(
          width: 104,
          child: Text(label, style: AppText.caption),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: AppText.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final IconData changeIcon;
  final String changeText;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.changeIcon,
    required this.changeText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: AppText.caption)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.title.copyWith(fontSize: 24)),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(changeIcon, size: 18, color: AppColors.secondaryText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  changeText,
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl - 2),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, size: 36, color: scheme.primary),
            const SizedBox(height: AppSpace.md),
            Text(title, style: AppText.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: AppText.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String dateText;
  final String weight;
  final String height;
  final String note;

  const _HistoryCard({
    required this.dateText,
    required this.weight,
    required this.height,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.show_chart_rounded, color: scheme.primary),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateText, style: AppText.subtitle),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Berat $weight · Tinggi $height',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: AppText.body.copyWith(color: AppColors.secondaryText),
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

// =============================================================================
// GRAFIK KMS DENGAN SKALA SUMBU Y & LABEL TITIK
// =============================================================================
class _GrowthChartPainter extends CustomPainter {
  final List<double> values;
  final List<DateTime?> dates;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final String firstLabel;
  final String lastLabel;
  final bool isWeight;
  final String unit;

  const _GrowthChartPainter({
    required this.values,
    required this.dates,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
    required this.firstLabel,
    required this.lastLabel,
    this.isWeight = true,
    this.unit = 'kg',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const left = 44.0;
    const right = 14.0;
    const top = 16.0;
    const bottom = 32.0;

    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    final yellowPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(chart, const Radius.circular(8)),
      yellowPaint,
    );

    final greenPaint = Paint()
      ..color = const Color(0xFFBBF7D0)
      ..style = PaintingStyle.fill;

    final normalBand = Path();
    normalBand.moveTo(chart.left, chart.bottom - chart.height * 0.28);
    normalBand.cubicTo(
      chart.left + chart.width * 0.35,
      chart.bottom - chart.height * 0.38,
      chart.left + chart.width * 0.65,
      chart.bottom - chart.height * 0.52,
      chart.right,
      chart.bottom - chart.height * 0.64,
    );
    normalBand.lineTo(chart.right, chart.bottom - chart.height * 0.90);
    normalBand.cubicTo(
      chart.left + chart.width * 0.65,
      chart.bottom - chart.height * 0.78,
      chart.left + chart.width * 0.35,
      chart.bottom - chart.height * 0.64,
      chart.left,
      chart.bottom - chart.height * 0.54,
    );
    normalBand.close();

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(chart, const Radius.circular(8)));
    canvas.drawPath(normalBand, greenPaint);

    double lower = isWeight ? 2.0 : 45.0;
    double upper = isWeight ? 20.0 : 110.0;

    if (values.isNotEmpty) {
      final minValue = values.reduce(math.min);
      final maxValue = values.reduce(math.max);
      final spread = (maxValue - minValue).abs();
      final margin = spread == 0
          ? (isWeight ? 2.5 : 8.0)
          : math.max(spread * 0.35, isWeight ? 1.5 : 5.0);
      lower = math.max(0, minValue - margin);
      upper = maxValue + margin;
    }
    final totalRange = (upper - lower) == 0 ? 1.0 : (upper - lower);

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const steps = 4;
    for (int s = 1; s < steps; s++) {
      final y = chart.bottom - (chart.height * (s / steps));
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    canvas.restore();

    final yAxisStyle = labelStyle.copyWith(
      color: AppColors.secondaryText,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
    );

    for (int s = 0; s <= steps; s++) {
      final ratio = s / steps;
      final val = lower + (totalRange * ratio);
      final y = chart.bottom - (chart.height * ratio);

      final tp = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(1), style: yAxisStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chart.left - tp.width - 6, y - tp.height / 2));
    }

    final List<Offset> points = [];

    if (values.isNotEmpty) {
      for (var i = 0; i < values.length; i++) {
        final fractionX = values.length == 1 ? 0.5 : i / (values.length - 1);
        final x = chart.left + chart.width * (0.1 + 0.8 * fractionX);
        final fractionY = ((values[i] - lower) / totalRange).clamp(0.12, 0.88);
        final y = chart.bottom - (chart.height * fractionY);
        points.add(Offset(x, y));
      }
    }

    if (points.length > 1) {
      final curvePath = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        curvePath.lineTo(points[i].dx, points[i].dy);
      }

      final curvePaint = Paint()
        ..color = const Color(0xFF15803D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(curvePath, curvePaint);
    }

    final pointLabelStyle = labelStyle.copyWith(
      color: const Color(0xFF14532D),
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
    );

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        pt,
        4.0,
        Paint()
          ..color = const Color(0xFF15803D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      final valPainter = TextPainter(
        text: TextSpan(
          text: values[i].toStringAsFixed(1),
          style: pointLabelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valPainter.paint(
        canvas,
        Offset(pt.dx - valPainter.width / 2, pt.dy - valPainter.height - 7),
      );
    }

    final labelStyleSecondary = labelStyle.copyWith(
      color: AppColors.secondaryText,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
    );

    final agePainter = TextPainter(
      text: TextSpan(
        text: firstLabel.isEmpty ? 'Usia (bulan)' : firstLabel,
        style: labelStyleSecondary,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    agePainter.paint(canvas, Offset(chart.left, chart.bottom + 10));

    final rightText = lastLabel.isNotEmpty && lastLabel != firstLabel
        ? lastLabel
        : (isWeight ? 'Berat ($unit)' : 'Tinggi ($unit)');
    final metricPainter = TextPainter(
      text: TextSpan(text: rightText, style: labelStyleSecondary),
      textDirection: TextDirection.ltr,
    )..layout();
    metricPainter.paint(
      canvas,
      Offset(chart.right - metricPainter.width, chart.bottom + 10),
    );
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.isWeight != isWeight ||
        oldDelegate.unit != unit ||
        !listEquals(oldDelegate.values, values);
  }
}