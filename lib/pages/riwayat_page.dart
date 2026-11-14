import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'artikel_page.dart';
import 'data_anak_page.dart';
import 'home_kader_page.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'login_page.dart';
import 'pemeriksaan_page.dart';
import 'profil_page.dart';

class RiwayatPage extends StatefulWidget {
  final bool isKader;
  final bool onlyVaccinations;

  const RiwayatPage({
    super.key,
    this.isKader = false,
    this.onlyVaccinations = false,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final _supabase = Supabase.instance.client;

  List<_HistoryEntry> _entries = [];
  bool _isLoading = true;
  bool _noChildren = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
  Future<void> _loadHistory() async {
    final user = _supabase.auth.currentUser;

    if (!widget.isKader && user == null) {
      setState(() {
        _loadError = 'Sesi login tidak ditemukan. Silakan masuk kembali.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final List<Map<String, dynamic>> children;

      if (widget.isKader) {
        children = await _supabase.from('anak').select('id, nama');
      } else {
        children = await _supabase
            .from('anak')
            .select('id, nama')
            .eq('user_id', user!.id);
      }

      final childNames = <Object, String>{};
      for (final child in children) {
        final id = child['id'];
        if (id is Object) childNames[id] = child['nama']?.toString() ?? '-';
      }

      if (childNames.isEmpty) {
        if (!mounted) return;
        setState(() {
          _entries = [];
          _noChildren = true;
          _isLoading = false;
        });
        return;
      }

      final ids = childNames.keys.toList();

      final examinations = await _supabase
          .from('pemeriksaan')
          .select()
          .inFilter('anak_id', ids)
          .order('tanggal', ascending: true);

      final vaccinations = await _supabase
          .from('imunisasi')
          .select()
          .inFilter('anak_id', ids)
          .order('tanggal', ascending: true);

      String measure(Object? value, String unit) =>
          value == null ? '-' : '$value $unit';

      final entries = <_HistoryEntry>[
        for (final item in examinations)
          _HistoryEntry(
            isVaccination: false,
            childName: childNames[item['anak_id']] ?? 'Anak tidak ditemukan',
            date: item['tanggal']?.toString() ?? '',
            detail:
                'Berat ${measure(item['berat_badan'], 'kg')} · '
                'Tinggi ${measure(item['tinggi_badan'], 'cm')}',
            note: item['catatan']?.toString() ?? '',
          ),
        for (final item in vaccinations)
          _HistoryEntry(
            isVaccination: true,
            childName: childNames[item['anak_id']] ?? 'Anak tidak ditemukan',
            date: item['tanggal']?.toString() ?? '',
            detail: item['nama_vaksin']?.toString() ?? 'Imunisasi',
            note: item['keterangan']?.toString() ?? '',
          ),
      ];

      // Terbaru di atas.
      entries.sort((a, b) {
        final dateA = DateTime.tryParse(a.date);
        final dateB = DateTime.tryParse(b.date);
        if (dateA == null || dateB == null) return b.date.compareTo(a.date);
        return dateB.compareTo(dateA);
      });

      if (widget.onlyVaccinations) {
        entries.removeWhere((entry) => !entry.isVaccination);
      }

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _noChildren = false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = friendlyError(
          error,
          fallback: 'Riwayat belum bisa dimuat. Coba lagi sebentar lagi.',
        );
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // KELUAR AKUN
  // ---------------------------------------------------------------------------
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
      await _supabase.auth.signOut();

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

  // ---------------------------------------------------------------------------
  // NAVIGASI (Orang Tua)
  // ---------------------------------------------------------------------------
  void _onParentNavigationTap(BuildContext context, int index) {
    final Widget? page = switch (index) {
      0 => const HomeOrtuPage(),
      1 => const DataAnakPage(),
      2 => const JadwalPage(),
      3 => const ArtikelPage(),
      4 => const ProfilPage(),
      _ => null,
    };

    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  // ---------------------------------------------------------------------------
  // ISI BERSAMA
  // ---------------------------------------------------------------------------
  Widget _scrollableState(Widget child) {
    // Dibungkus agar tarik-untuk-memperbarui tetap berfungsi di keadaan kosong.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Memuat riwayat');
    }

    if (_loadError != null) {
      return ErrorState(
        title: 'Riwayat belum bisa dimuat',
        message: _loadError!,
        onRetry: _loadHistory,
      );
    }

    if (_entries.isEmpty) {
      final EmptyState empty;

      if (_noChildren) {
        empty = EmptyState(
          icon: Icons.child_care_rounded,
          title: 'Belum ada data anak',
          message: widget.isKader
              ? 'Riwayat akan muncul setelah ada anak yang terdaftar di Posyandu.'
              : 'Daftarkan anak di menu Anak untuk melihat riwayatnya.',
        );
      } else {
        empty = EmptyState(
          icon: widget.onlyVaccinations
              ? Icons.vaccines_outlined
              : Icons.history_rounded,
          title: widget.onlyVaccinations
              ? 'Belum ada catatan imunisasi'
              : 'Belum ada riwayat tercatat',
          message: widget.isKader
              ? 'Data pemeriksaan dan imunisasi akan muncul di sini.'
              : 'Catatan akan muncul setelah Kader mencatat pemeriksaan atau imunisasi anak Anda.',
        );
      }

      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: _scrollableState(empty),
      );
    }

    // Susunan: judul bulan, lalu catatan bulan itu (terbaru di atas).
    final children = <Widget>[];
    int? lastKey;

    for (final entry in _entries) {
      final date = DateTime.tryParse(entry.date);
      final key = date == null ? -1 : date.year * 100 + date.month;

      if (key != lastKey) {
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: lastKey == null ? 0 : AppSpace.lg,
              bottom: AppSpace.sm,
            ),
            child: Semantics(
              header: true,
              child: Text(
                date == null
                    ? 'Tanggal tidak diketahui'
                    : '${bulanLengkap(date.month)} ${date.year}',
                style: AppText.label.copyWith(color: AppColors.secondaryText),
              ),
            ),
          ),
        );
        lastKey = key;
      } else {
        children.add(const SizedBox(height: AppSpace.md));
      }

      children.add(
        _HistoryCard(
          entry: entry,
          dateText: date == null ? entry.date : tanggalLengkap(date),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.sm,
          AppSpace.page,
          AppSpace.xl,
        ),
        children: children,
      ),
    );
  }

  // ===========================================================================
  // TAMPILAN KADER
  // ===========================================================================
  Widget _buildKader(BuildContext context) {
    return Theme(
      data: AppTheme.kader,
      child: Scaffold(
        floatingActionButton: KaderCenterFab(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PemeriksaanPage(openFormOnStart: true),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: KaderBottomAppBar(
          selectedIndex: -1,
          onTabSelected: (index) {
            final Widget? page = switch (index) {
              0 => const HomeKaderPage(),
              1 => const DataAnakPage(isKader: true),
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
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.sm,
                ),
                child: KaderTopBar(
                  title: 'Riwayat Global',
                  subtitle: _isLoading || _loadError != null
                      ? 'Catatan pemeriksaan & imunisasi Posyandu'
                      : '${_entries.length} catatan pemeriksaan & imunisasi',
                  onBack: () => Navigator.maybePop(context),
                  trailing: KaderLogoutButton(onPressed: _logout),
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAMPILAN ORANG TUA
  // ===========================================================================
  Widget _buildParent(BuildContext context) {
    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.onlyVaccinations ? 'Riwayat Imunisasi' : 'Riwayat Anak',
          ),
        ),
        body: _buildBody(),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 1,
          onTap: (index) => _onParentNavigationTap(context, index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isKader ? _buildKader(context) : _buildParent(context);
  }
}

// =============================================================================
// KARTU RIWAYAT
// =============================================================================
class _HistoryCard extends StatelessWidget {
  final _HistoryEntry entry;
  final String dateText;

  const _HistoryCard({required this.entry, required this.dateText});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVaccine = entry.isVaccination;

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
            child: Icon(
              isVaccine
                  ? Icons.vaccines_outlined
                  : Icons.monitor_weight_outlined,
              size: 24,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jenis catatan ditulis dengan teks, bukan hanya warna.
                Text(
                  isVaccine ? 'Imunisasi' : 'Pemeriksaan gizi',
                  style: AppText.caption.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(entry.childName, style: AppText.subtitle),
                Text(dateText, style: AppText.caption),
                const SizedBox(height: AppSpace.sm),
                Text(
                  entry.detail,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.notes_rounded,
                          size: 16,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.note,
                          style: AppText.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
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

class _HistoryEntry {
  final bool isVaccination;
  final String childName;
  final String date;
  final String detail;
  final String note;

  const _HistoryEntry({
    required this.isVaccination,
    required this.childName,
    required this.date,
    required this.detail,
    required this.note,
  });
}
