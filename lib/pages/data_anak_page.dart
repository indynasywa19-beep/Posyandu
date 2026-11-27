import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../utils/validators.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'home_ortu_page.dart';
import 'jadwal_page.dart';
import 'perkembangan_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

typedef AnakRecord = Map<String, dynamic>;

int? _hitungUsiaBulan(String? birthIso) {
  if (birthIso == null || birthIso.isEmpty) return null;
  final birth = DateTime.tryParse(birthIso);
  if (birth == null) return null;
  final now = DateTime.now();
  final months = (now.year - birth.year) * 12 + (now.month - birth.month);
  return months < 0 ? 0 : months;
}

bool _isLulusBalita(String? birthIso) {
  final months = _hitungUsiaBulan(birthIso);
  return months != null && months >= 60;
}

class DataAnakPage extends StatefulWidget {
  final bool isKader;

  const DataAnakPage({super.key, this.isKader = false});

  @override
  State<DataAnakPage> createState() => _DataAnakPageState();
}

class _DataAnakPageState extends State<DataAnakPage> {
  final _supabase = Supabase.instance.client;

  List<AnakRecord> _children = [];
  Map<String, String> _latestStatusMap = {};
  bool _isLoading = true;
  String? _loadError;
  String _searchQuery = '';
  String _statusFilter = 'Semua status';

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final user = _supabase.auth.currentUser;

    if (!widget.isKader && user == null) {
      setState(() {
        _children = [];
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
      final List rows;

      if (widget.isKader) {
        rows = await _supabase.from('anak').select().order('nama');
      } else {
        rows = await _supabase
            .from('anak')
            .select()
            .eq('user_id', user!.id)
            .order('nama');
      }

      final Map<String, String> statusMap = {};
      try {
        final pRows = await _supabase
            .from('pemeriksaan')
            .select('anak_id, berat_badan, tanggal')
            .order('tanggal', ascending: false);

        for (final p in pRows) {
          final anakId = p['anak_id']?.toString() ?? '';
          if (anakId.isEmpty || statusMap.containsKey(anakId)) continue;
          final bb = double.tryParse(p['berat_badan']?.toString() ?? '') ?? 0;
          statusMap[anakId] =
              bb > 0 && bb < 7.0 ? 'Perlu perhatian' : 'Gizi baik';
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _children = List<AnakRecord>.from(rows);
        _latestStatusMap = statusMap;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = friendlyError(
          error,
          fallback: 'Data anak belum bisa dimuat. Coba lagi sebentar lagi.',
        );
        _isLoading = false;
      });
    }
  }

  String _getStatusAnak(AnakRecord child) {
    if (_isLulusBalita(child['tanggal_lahir']?.toString())) {
      return 'Lulus Balita';
    }
    final id = child['id']?.toString() ?? '';
    return _latestStatusMap[id] ?? 'Gizi baik';
  }

  void _openChildDetail(AnakRecord child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PerkembanganPage(isKader: widget.isKader, anakId: child['id']),
      ),
    );
  }

  void _showContactParentDialog(AnakRecord child) {
    final namaAnak = child['nama']?.toString() ?? '-';
    final namaOrtu = (child['nama_ortu']?.toString() ?? '').trim();
    final noHp = (child['no_hp']?.toString() ?? '').trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kontak Orang Tua', style: AppText.title),
                          Text(
                            'Anak: $namaAnak',
                            style: AppText.caption.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama Orang Tua / Wali', style: AppText.caption),
                      const SizedBox(height: 2),
                      Text(
                        namaOrtu.isEmpty ? 'Belum diisi' : namaOrtu,
                        style: AppText.subtitle,
                      ),
                      const Divider(height: 20),
                      Text('Nomor HP / WhatsApp', style: AppText.caption),
                      const SizedBox(height: 2),
                      Text(
                        noHp.isEmpty
                            ? 'Belum diisi (ubah data anak untuk melengkapi)'
                            : noHp,
                        style: AppText.subtitle.copyWith(
                          color: noHp.isEmpty
                              ? AppColors.secondaryText
                              : AppColors.logoGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (noHp.isNotEmpty) ...[
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: noHp));
                      Navigator.pop(ctx);
                      _showMessage(
                        'Nomor $noHp disalin. Siap dihubungi via WhatsApp.',
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin Nomor WA'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.logoGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _tanggalTampil(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final date = DateTime.tryParse(iso);
    return date == null ? iso : tanggalLengkap(date);
  }

  Future<void> _showForm({AnakRecord? child}) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => Theme(
        data: AppTheme.forRole(isKader: widget.isKader),
        child: Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _ChildFormSheet(child: child, isKader: widget.isKader),
            ),
          ),
        ),
      ),
    );

    if (!mounted || message == null) return;

    _showMessage(message);
    await _loadChildren();
  }

  Future<void> _deleteChild(AnakRecord child) async {
    final nama = child['nama']?.toString() ?? 'anak ini';

    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus data anak?',
      message: 'Data $nama akan dihapus dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _supabase.from('anak').delete().eq('id', child['id']);

      _showMessage('Data $nama dihapus.');
      await _loadChildren();
    } catch (error) {
      _showMessage(
        friendlyError(
          error,
          fallback: 'Data anak belum bisa dihapus. Coba lagi.',
        ),
      );
    }
  }

  void _onParentNavigationTap(BuildContext context, int index) {
    final Widget? page = switch (index) {
      0 => const HomeOrtuPage(),
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

  List<AnakRecord> get _visibleChildren {
    final query = _searchQuery.trim().toLowerCase();

    return _children.where((child) {
      final matchesQuery = query.isEmpty ||
          (child['nama']?.toString().toLowerCase().contains(query) ?? false) ||
          (child['nik']?.toString().contains(query) ?? false) ||
          (child['nama_ortu']?.toString().toLowerCase().contains(query) ??
              false);

      if (!matchesQuery) return false;

      if (_statusFilter == 'Semua status') return true;
      return _getStatusAnak(child) == _statusFilter;
    }).toList();
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'Lulus Balita') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Text(
          'Lulus Balita',
          style: AppText.caption.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      );
    }
    return StatusGiziBadge(status: status);
  }

  Widget _buildKader(BuildContext context) {
    final visible = _visibleChildren;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return KaderWebScaffold(
      activeIndex: 1,
      breadcrumb: 'Beranda / Monitoring Anak',
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;

                  final searchWidget = AppSearchField(
                    hint: 'Cari nama anak, orang tua, atau NIK',
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                  );

                  final filterDropdown = Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.secondaryText,
                        ),
                        style: AppText.body.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Semua status',
                            child: Text('Semua status'),
                          ),
                          DropdownMenuItem(
                            value: 'Gizi baik',
                            child: Text('Gizi baik'),
                          ),
                          DropdownMenuItem(
                            value: 'Perlu perhatian',
                            child: Text('Perlu perhatian'),
                          ),
                          DropdownMenuItem(
                            value: 'Lulus Balita',
                            child: Text('Lulus Balita (≥ 5 Thn)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _statusFilter = val);
                          }
                        },
                      ),
                    ),
                  );

                  final addButton = FilledButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Tambah anak'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(140, 48),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchWidget,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: filterDropdown),
                            const SizedBox(width: 10),
                            addButton,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 5, child: searchWidget),
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: filterDropdown),
                      const SizedBox(width: 14),
                      addButton,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              Text(
                _searchQuery.isEmpty && _statusFilter == 'Semua status'
                    ? '${_children.length} anak terdaftar'
                    : '${visible.length} dari ${_children.length} anak ditemukan',
                style: AppText.caption.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: LoadingState(message: 'Memuat data anak'),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ErrorState(
                    message: _loadError!,
                    onRetry: _loadChildren,
                  ),
                )
              else if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Tidak ada anak yang cocok',
                    message: 'Coba ubah kata kunci atau pilihan filter.',
                    actionLabel: 'Tambah anak baru',
                    onAction: () => _showForm(),
                  ),
                )
              else if (isMobile)
                Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildKaderMobileCard(visible[i]),
                    ],
                  ],
                )
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          'No',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Nama Anak',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Orang Tua / Wali',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Tgl Lahir',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Status',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 170,
                        child: Text(
                          'Aksi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                for (var i = 0; i < visible.length; i++)
                  _buildTableRow(visible[i], i),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKaderMobileCard(AnakRecord child) {
    final name = child['nama']?.toString() ?? '-';
    final nik = child['nik']?.toString() ?? '-';
    final tgl = _tanggalTampil(child['tanggal_lahir']?.toString());
    final jk = child['jenis_kelamin']?.toString() ?? '-';
    final ortu = (child['nama_ortu']?.toString() ?? '').trim();
    final noHp = (child['no_hp']?.toString() ?? '').trim();
    final status = _getStatusAnak(child);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: name, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppText.subtitle.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$jk · $tgl',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 10),
          Text('NIK: $nik', style: AppText.caption),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ortu: ${ortu.isEmpty ? "Belum diisi" : ortu}${noHp.isNotEmpty ? " ($noHp)" : ""}',
                  style: AppText.caption.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showContactParentDialog(child),
                icon: const Icon(Icons.phone_outlined, size: 17),
                label: const Text('Hubungi'),
              ),
              IconButton(
                tooltip: 'KMS / Perkembangan',
                icon: const Icon(Icons.show_chart_rounded, color: AppColors.navy),
                onPressed: () => _openChildDetail(child),
              ),
              IconButton(
                tooltip: 'Ubah',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showForm(child: child),
              ),
              IconButton(
                tooltip: 'Hapus',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppStatus.danger.foreground,
                ),
                onPressed: () => _deleteChild(child),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(AnakRecord child, int index) {
    final name = child['nama']?.toString() ?? '-';
    final nik = child['nik']?.toString() ?? '-';
    final tgl = _tanggalTampil(child['tanggal_lahir']?.toString());
    final ortu = (child['nama_ortu']?.toString() ?? '').trim();
    final noHp = (child['no_hp']?.toString() ?? '').trim();
    final status = _getStatusAnak(child);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${index + 1}',
              style: AppText.caption.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _openChildDetail(child),
              child: Row(
                children: [
                  InitialsAvatar(name: name, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          'NIK: $nik',
                          style: AppText.caption.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ortu.isEmpty ? 'Belum diisi' : ortu,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (noHp.isNotEmpty)
                  Text(
                    noHp,
                    style: AppText.caption.copyWith(
                      color: AppColors.logoGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tgl,
              style: AppText.caption.copyWith(
                color: AppColors.text,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(status),
            ),
          ),
          SizedBox(
            width: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Hubungi orang tua',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.phone_outlined,
                    size: 19,
                    color: AppColors.logoGreen,
                  ),
                  onPressed: () => _showContactParentDialog(child),
                ),
                IconButton(
                  tooltip: 'Lihat perkembangan',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.show_chart_rounded,
                    size: 20,
                    color: AppColors.navy,
                  ),
                  onPressed: () => _openChildDetail(child),
                ),
                IconButton(
                  tooltip: 'Ubah data',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () => _showForm(child: child),
                ),
                IconButton(
                  tooltip: 'Hapus data',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: AppStatus.danger.foreground,
                  ),
                  onPressed: () => _deleteChild(child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParent(BuildContext context) {
    return Theme(
      data: AppTheme.parent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Data Anak')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          backgroundColor: AppColors.parent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah anak'),
        ),
        body: _buildParentBody(),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 1,
          onTap: (index) => _onParentNavigationTap(context, index),
        ),
      ),
    );
  }

  Widget _buildParentBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Memuat data anak');
    }

    if (_loadError != null) {
      return ErrorState(message: _loadError!, onRetry: _loadChildren);
    }

    return RefreshIndicator(
      onRefresh: _loadChildren,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.md,
          AppSpace.page,
          96,
        ),
        children: [
          _parentProfileCard(),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(
            title: 'Anak terdaftar',
            subtitle: '${_children.length} anak',
          ),
          const SizedBox(height: AppSpace.md),
          if (_children.isEmpty)
            EmptyState(
              icon: Icons.child_care_rounded,
              title: 'Belum ada data anak',
              message:
                  'Daftarkan identitas si kecil (0–6 tahun) untuk mulai memantau.',
              actionLabel: 'Tambahkan data anak',
              onAction: () => _showForm(),
            )
          else
            for (var i = 0; i < _children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.md),
              _parentChildCard(_children[i]),
            ],
        ],
      ),
    );
  }

  Widget _parentChildCard(AnakRecord child) {
    final name = child['nama']?.toString() ?? 'Tanpa nama';
    final noHp = (child['no_hp']?.toString() ?? '').trim();
    final birthIso = child['tanggal_lahir']?.toString();
    final isGraduated = _isLulusBalita(birthIso);

    return AppCard(
      onTap: () => _openChildDetail(child),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InitialsAvatar(name: name, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChildInfo(
                  name: name,
                  gender: child['jenis_kelamin']?.toString() ?? '-',
                  birthDate: _tanggalTampil(birthIso),
                  nik: child['nik']?.toString() ?? '-',
                ),
                if (noHp.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'WA Ortu: $noHp',
                    style: AppText.caption.copyWith(
                      color: AppColors.logoGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isGraduated
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isGraduated
                        ? 'Lulus Balita · Arsip Riwayat KMS'
                        : 'KMS Balita Aktif (0–59 Bulan)',
                    style: AppText.caption.copyWith(
                      color: isGraduated
                          ? AppColors.navy
                          : const Color(0xFF15803D),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah data anak',
            onPressed: () => _showForm(child: child),
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.navy,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }

  Widget _parentProfileCard() {
    final user = _supabase.auth.currentUser;
    final parentName = displayNameFromUser(
      user,
      fallback: 'Orang Tua / Wali',
    );
    final phone = (user?.userMetadata?['phone']?.toString() ?? '').trim();

    return AppCard(
      color: AppColors.parentTint,
      child: Row(
        children: [
          InitialsAvatar(name: parentName, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parentName, style: AppText.subtitle),
                Text('Orang Tua / Wali', style: AppText.caption),
                Text(
                  user?.email ?? '-',
                  style: AppText.caption.copyWith(
                    color: AppColors.parent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (phone.isNotEmpty)
                  Text(
                    'WA: $phone',
                    style: AppText.caption.copyWith(
                      color: AppColors.logoGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilPage()),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isKader ? _buildKader(context) : _buildParent(context);
  }
}

class _ChildInfo extends StatelessWidget {
  final String name;
  final String gender;
  final String birthDate;
  final String nik;

  const _ChildInfo({
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.nik,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppText.subtitle),
        const SizedBox(height: 2),
        Text('$gender · Lahir $birthDate', style: AppText.caption),
        Text('NIK: $nik', style: AppText.caption),
      ],
    );
  }
}

class _ChildFormSheet extends StatefulWidget {
  final AnakRecord? child;
  final bool isKader;

  const _ChildFormSheet({required this.child, required this.isKader});

  @override
  State<_ChildFormSheet> createState() => _ChildFormSheetState();
}

class _ChildFormSheetState extends State<_ChildFormSheet> {
  static const _genders = ['Laki-laki', 'Perempuan'];
  static const _maxAgeMonths = 72;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nikCtrl;
  late final TextEditingController _ortuCtrl;
  late final TextEditingController _hpCtrl;

  DateTime? _birthDate;
  String _gender = '';

  bool _isSaving = false;
  bool _autoValidate = false;
  String? _birthError;
  String? _genderError;
  String? _errorMessage;

  bool get _isEdit => widget.child != null;

  int? get _selectedAgeMonths {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    final months =
        (now.year - _birthDate!.year) * 12 + (now.month - _birthDate!.month);
    return months < 0 ? 0 : months;
  }

  bool get _isOverMaxAge {
    final months = _selectedAgeMonths;
    return months != null && months > _maxAgeMonths;
  }

  @override
  void initState() {
    super.initState();

    final c = widget.child;
    final user = Supabase.instance.client.auth.currentUser;
    final defaultOrtu = widget.isKader
        ? ''
        : displayNameFromUser(user, fallback: '');
    final defaultHp = widget.isKader
        ? ''
        : (user?.userMetadata?['phone']?.toString() ?? '');

    _nameCtrl = TextEditingController(text: c?['nama']?.toString() ?? '');
    _nikCtrl = TextEditingController(text: c?['nik']?.toString() ?? '');
    _ortuCtrl = TextEditingController(
      text: c?['nama_ortu']?.toString() ?? defaultOrtu,
    );
    _hpCtrl = TextEditingController(
      text: c?['no_hp']?.toString() ?? defaultHp,
    );
    final rawBirth = c?['tanggal_lahir']?.toString();
    if (rawBirth != null && rawBirth.isNotEmpty) {
      _birthDate = DateTime.tryParse(rawBirth);
    }

    final rawGender = c?['jenis_kelamin']?.toString();
    if (rawGender != null && _genders.contains(rawGender)) {
      _gender = rawGender;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    _ortuCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  String? _validateNik(String? value) {
    final nik = value ?? '';
    if (nik.isEmpty) return 'NIK wajib diisi.';
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      return 'NIK harus terdiri dari 16 digit angka (sekarang ${nik.length}).';
    }
    return null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    var initial = _birthDate ?? now;
    if (initial.isAfter(now)) initial = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir Anak',
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
        _birthError = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_isEdit && _isOverMaxAge) return;

    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final formOk = _formKey.currentState!.validate();
    final birthOk = _birthDate != null;
    final genderOk = _gender.isNotEmpty;

    setState(() {
      _birthError = birthOk ? null : 'Pilih tanggal lahir.';
      _genderError = genderOk ? null : 'Pilih jenis kelamin.';
      if (!formOk || !birthOk || !genderOk) {
        _autoValidate = true;
      }
    });

    if (!formOk || !birthOk || !genderOk) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(
        () => _errorMessage = 'Sesi login berakhir. Silakan masuk kembali.',
      );
      return;
    }

    setState(() => _isSaving = true);

    final birth = _birthDate!;
    final ortuName = _ortuCtrl.text.trim();
    final hpNumber = _hpCtrl.text.trim();
    final ageMonths = _selectedAgeMonths ?? 0;
    final statusKepesertaan = ageMonths >= 60 ? 'Lulus Balita' : 'Aktif';

    final data = {
      'nama': _nameCtrl.text.trim(),
      'nik': _nikCtrl.text,
      'tanggal_lahir':
          '${birth.year.toString().padLeft(4, '0')}-'
          '${birth.month.toString().padLeft(2, '0')}-'
          '${birth.day.toString().padLeft(2, '0')}',
      'jenis_kelamin': _gender,
      'nama_ortu': ortuName,
      'no_hp': hpNumber,
      'status_kepesertaan': statusKepesertaan,
    };

    try {
      final supabase = Supabase.instance.client;
      final ownerUserId = widget.child?['user_id']?.toString() ??
          (!widget.isKader ? user.id : null);

      if (widget.child == null) {
        await supabase.from('anak').insert({...data, 'user_id': user.id});
      } else {
        await supabase
            .from('anak')
            .update(data)
            .eq('id', widget.child!['id']);
      }

      if (ownerUserId != null && ownerUserId.isNotEmpty) {
        await supabase
            .from('anak')
            .update({
              'nama_ortu': ortuName,
              'no_hp': hpNumber,
            })
            .eq('user_id', ownerUserId);
      }

      if (!widget.isKader) {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'display_name': ortuName,
              'phone': hpNumber,
            },
          ),
        );
      }

      if (!mounted) return;

      final nama = data['nama'].toString();
      Navigator.pop(
        context,
        _isEdit
            ? 'Perubahan data $nama disimpan.'
            : '$nama berhasil didaftarkan.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = friendlyError(
          error,
          fallback:
              'Data anak belum tersimpan. Periksa koneksi internet, lalu coba lagi.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height;
    final ageMonths = _selectedAgeMonths;
    final blockedByAge = !_isEdit && _isOverMaxAge;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                0,
                AppSpace.sm,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            _isEdit ? 'Ubah data anak' : 'Daftarkan si kecil',
                            style: AppText.title,
                          ),
                        ),
                        Text(
                          'Khusus layanan Posyandu Anak usia 0–6 tahun (maks. 72 bulan).',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.sm,
                  AppSpace.page,
                  AppSpace.lg,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Nama anak',
                        controller: _nameCtrl,
                        prefixIcon: Icons.child_care_outlined,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => validateRequired(v, 'Nama anak'),
                      ),
                      const SizedBox(height: AppSpace.lg),

                      AppTextField(
                        label: 'NIK',
                        controller: _nikCtrl,
                        helper: 'Terdiri dari 16 digit angka.',
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 16,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateNik,
                      ),
                      const SizedBox(height: AppSpace.md),

                      AppTextField(
                        label: 'Nama Orang Tua / Wali',
                        controller: _ortuCtrl,
                        hint: 'Contoh: Ibu Siti / Bapak Alan',
                        prefixIcon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            validateRequired(v, 'Nama orang tua'),
                      ),
                      const SizedBox(height: AppSpace.lg),

                      AppTextField(
                        label: 'No. HP / WhatsApp Orang Tua',
                        controller: _hpCtrl,
                        hint: 'Contoh: 081234567890',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: AppSpace.lg),

                      Text('Tanggal lahir', style: AppText.label),
                      const SizedBox(height: 6),
                      AppPickerTile(
                        icon: Icons.calendar_month_outlined,
                        value: _birthDate == null
                            ? 'Pilih tanggal lahir'
                            : '${tanggalLengkap(_birthDate!)} (${ageMonths! ~/ 12} thn ${ageMonths % 12} bln)',
                        isPlaceholder: _birthDate == null,
                        semanticLabel: _birthDate == null
                            ? 'Tanggal lahir belum dipilih. Pilih tanggal lahir'
                            : 'Tanggal lahir ${tanggalLengkap(_birthDate!)}. Ubah tanggal',
                        onTap: _pickBirthDate,
                      ),
                      if (_birthError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _birthError!,
                          style: AppText.caption.copyWith(
                            color: AppStatus.danger.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (blockedByAge && ageMonths != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppStatus.danger.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppStatus.danger.foreground.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: AppStatus.danger.foreground,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Usia anak saat ini ${ageMonths ~/ 12} tahun ($ageMonths bulan), sudah melewati batas maksimal Posyandu Anak (6 tahun / lulus balita). Pendaftaran tidak dapat dilanjutkan.',
                                  style: AppText.caption.copyWith(
                                    color: AppStatus.danger.foreground,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.lg),

                      Text('Jenis kelamin', style: AppText.label),
                      const SizedBox(height: AppSpace.sm),
                      ChoiceChipGroup(
                        options: _genders,
                        selected: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                            if (value.isNotEmpty) _genderError = null;
                          });
                        },
                      ),
                      if (_genderError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _genderError!,
                          style: AppText.caption.copyWith(
                            color: AppStatus.danger.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.lg,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null) ...[
                      InlineMessage(message: _errorMessage!),
                      const SizedBox(height: AppSpace.md),
                    ],
                    AppButton(
                      label: blockedByAge
                          ? 'Melebihi Batas Usia Posyandu'
                          : (_isEdit ? 'Simpan perubahan' : 'Daftarkan anak'),
                      onPressed: blockedByAge ? null : _save,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}