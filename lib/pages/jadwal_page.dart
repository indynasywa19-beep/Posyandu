import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_copy.dart';
import '../utils/validators.dart';
import '../widgets/app_components.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_tokens.dart';
import '../widgets/kader_widgets.dart';
import 'data_anak_page.dart';
import 'home_ortu_page.dart';
import 'login_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

class JadwalPage extends StatefulWidget {
  final bool isKader;

  const JadwalPage({super.key, this.isKader = false});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _supabase = Supabase.instance.client;

  List _schedules = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------
  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final schedules = await _supabase
          .from('jadwal')
          .select()
          .order('tanggal');

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = friendlyError(
          error,
          fallback: 'Jadwal belum bisa dimuat. Coba lagi sebentar lagi.',
        );
        _isLoading = false;
      });
    }
  }

  ({List upcoming, List past}) _grouped() {
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming = [];
    final past = [];

    for (final schedule in _schedules) {
      final date = DateTime.tryParse(schedule['tanggal']?.toString() ?? '');

      if (date != null && DateUtils.dateOnly(date).isBefore(today)) {
        past.add(schedule);
      } else {
        upcoming.add(schedule);
      }
    }

    return (upcoming: upcoming, past: past.reversed.toList());
  }

  String _tanggalTampil(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final date = DateTime.tryParse(iso);
    return date == null ? iso : tanggalLengkap(date);
  }

  static String _waktuTampil(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    return RegExp(r'^\d{2}:\d{2}').hasMatch(raw) ? raw.substring(0, 5) : raw;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // FORM TAMBAH / UBAH (Dialog Tengah di Web, BottomSheet di HP)
  // ---------------------------------------------------------------------------
  Future<void> _editSchedule({Map? schedule}) async {
    final String? message;

    if (widget.isKader) {
      message = await showDialog<String>(
        context: context,
        builder: (_) => Theme(
          data: AppTheme.kader,
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _ScheduleFormSheet(schedule: schedule),
              ),
            ),
          ),
        ),
      );
    } else {
      message = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => Theme(
          data: AppTheme.kader,
          child: _ScheduleFormSheet(schedule: schedule),
        ),
      );
    }

    if (!mounted || message == null) return;

    _showMessage(message);
    await _loadSchedules();
  }

  // ---------------------------------------------------------------------------
  // HAPUS
  // ---------------------------------------------------------------------------
  Future<void> _deleteSchedule(Map schedule) async {
    final tanggal = _tanggalTampil(schedule['tanggal']?.toString());
    final lokasi = schedule['lokasi']?.toString() ?? '-';

    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus jadwal?',
      message:
          'Jadwal $tanggal di $lokasi akan dihapus dari Posyandu dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _supabase.from('jadwal').delete().eq('id', schedule['id']);

      _showMessage('Jadwal $tanggal dihapus.');
      await _loadSchedules();
    } catch (error) {
      _showMessage(
        friendlyError(
          error,
          fallback: 'Jadwal belum bisa dihapus. Coba lagi.',
        ),
      );
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
      _showMessage(
        friendlyError(
          error,
          fallback: 'Belum bisa keluar dari akun. Coba lagi.',
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

  // ---------------------------------------------------------------------------
  // ISI BERSAMA (Kader dan Orang Tua)
  // ---------------------------------------------------------------------------
  Widget _scrollableState(Widget child) {
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

Widget _buildBody({required bool isKader}) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingState(message: 'Memuat jadwal'),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorState(
          title: 'Jadwal belum bisa dimuat',
          message: _loadError!,
          onRetry: _loadSchedules,
        ),
      );
    }

    if (_schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: isKader
            ? EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'Belum ada jadwal Posyandu',
                message:
                    'Tambahkan jadwal agar orang tua tahu kapan dan di mana kegiatan berlangsung.',
                actionLabel: 'Tambah jadwal',
                onAction: () => _editSchedule(),
              )
            : const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'Belum ada jadwal Posyandu',
                message:
                    'Jadwal dibuat oleh Kader. Tarik layar ke bawah untuk memperbarui.',
              ),
      );
    }

    final groups = _grouped();
    final today = DateUtils.dateOnly(DateTime.now());

    Widget cardFor(Map schedule, {required bool isPast}) {
      final rawDate = schedule['tanggal']?.toString() ?? '';
      final date = DateTime.tryParse(rawDate);

      return _ScheduleCard(
        date: date,
        dateText: _tanggalTampil(rawDate),
        timeText: _waktuTampil(schedule['waktu']?.toString()),
        location: schedule['lokasi']?.toString() ?? '-',
        isPast: isPast,
        isToday: date != null && DateUtils.dateOnly(date) == today,
        onEdit: isKader ? () => _editSchedule(schedule: schedule) : null,
        onDelete: isKader ? () => _deleteSchedule(schedule) : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Akan datang',
          subtitle: groups.upcoming.isEmpty
              ? null
              : '${groups.upcoming.length} jadwal',
        ),
        const SizedBox(height: AppSpace.md),
        if (groups.upcoming.isEmpty)
          Text(
            'Belum ada jadwal yang akan datang.',
            style: AppText.body.copyWith(color: AppColors.secondaryText),
          )
        else
          for (var i = 0; i < groups.upcoming.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.md),
            cardFor(groups.upcoming[i] as Map, isPast: false),
          ],

        if (groups.past.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xl),
          SectionHeader(
            title: 'Sudah lewat',
            subtitle: '${groups.past.length} jadwal',
          ),
          const SizedBox(height: AppSpace.md),
          for (var i = 0; i < groups.past.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.md),
            cardFor(groups.past[i] as Map, isPast: true),
          ],
        ],

        if (!isKader) ...[
          const SizedBox(height: AppSpace.xl),
          const SectionHeader(title: 'Kegiatan layanan'),
          const SizedBox(height: AppSpace.sm),
          _activity(Icons.monitor_weight_outlined, 'Penimbangan'),
          _activity(Icons.height_rounded, 'Pengukuran tinggi badan'),
          _activity(Icons.vaccines_outlined, 'Imunisasi'),
          _activity(
            Icons.medical_services_outlined,
            'Pemeriksaan kesehatan',
          ),
        ],
      ],
    );
  }

    

  Widget _activity(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm - 1),
      child: Row(
        children: [
          Icon(icon, color: AppColors.parent),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(title, style: AppText.bodyLarge)),
        ],
      ),
    );
  }

  String _subtitle() {
    if (_isLoading || _loadError != null) return 'Jadwal kegiatan Posyandu';
    final upcoming = _grouped().upcoming.length;
    return upcoming == 0
        ? 'Belum ada jadwal yang akan datang'
        : '$upcoming jadwal akan datang';
  }

  // ===========================================================================
  // TAMPILAN KADER (Layout Web)
  // ===========================================================================
  Widget _buildKader(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return KaderWebScaffold(
      activeIndex: 4,
      breadcrumb: 'Beranda / Jadwal Posyandu',
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
              if (isMobile) ...[
                Text(
                  'Jadwal Posyandu',
                  style: AppText.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(),
                  style: AppText.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _editSchedule(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Tambah jadwal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jadwal Posyandu',
                            style: AppText.title.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle(),
                            style: AppText.caption.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _editSchedule(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Tambah jadwal'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(140, 48),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildBody(isKader: true),
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
        appBar: AppBar(title: const Text('Jadwal Posyandu')),
        body: RefreshIndicator(
          onRefresh: _loadSchedules,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpace.page,
              AppSpace.lg,
              AppSpace.page,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_subtitle(), style: AppText.caption),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hanya bisa dilihat · dibuat oleh Kader',
                          style: AppText.caption.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                _buildBody(isKader: false),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          isKader: false,
          selectedIndex: 2,
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
// KARTU JADWAL
// =============================================================================
class _ScheduleCard extends StatelessWidget {
  final DateTime? date;
  final String dateText;
  final String timeText;
  final String location;
  final bool isPast;
  final bool isToday;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ScheduleCard({
    required this.date,
    required this.dateText,
    required this.timeText,
    required this.location,
    required this.isPast,
    required this.isToday,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final badgeBackground = isPast
        ? AppStatus.neutral.background
        : scheme.primaryContainer;
    final badgeForeground = isPast
        ? AppStatus.neutral.foreground
        : scheme.primary;

    return AppCard(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        onEdit == null ? AppSpace.lg : AppSpace.xs,
        AppSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: AppRadius.controlAll,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  date == null ? '-' : date!.day.toString(),
                  style: AppText.title.copyWith(color: badgeForeground),
                ),
                Text(
                  date == null ? '' : bulanSingkat(date!.month),
                  style: AppText.caption.copyWith(
                    color: badgeForeground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateText, style: AppText.subtitle),
                if (isToday) ...[
                  const SizedBox(height: 4),
                  const StatusChip(label: 'Hari ini', status: AppStatus.info),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text('Pukul $timeText', style: AppText.body),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(location, style: AppText.body)),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null && onDelete != null)
            PopupMenuButton<String>(
              tooltip: 'Menu untuk jadwal $dateText',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit!();
                } else {
                  onDelete!();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: AppSpace.md),
                      Text('Ubah jadwal'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: AppStatus.danger.foreground,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Text(
                        'Hapus jadwal',
                        style: TextStyle(color: AppStatus.danger.foreground),
                      ),
                    ],
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
// LEMBAR FORM
// =============================================================================
class _ScheduleFormSheet extends StatefulWidget {
  final Map? schedule;

  const _ScheduleFormSheet({required this.schedule});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationCtrl;

  DateTime? _date;
  TimeOfDay? _time;

  bool _isSaving = false;
  bool _autoValidate = false;
  String? _dateError;
  String? _timeError;
  String? _errorMessage;

  bool get _isEdit => widget.schedule != null;

  @override
  void initState() {
    super.initState();

    final s = widget.schedule;

    _locationCtrl = TextEditingController(text: s?['lokasi']?.toString() ?? '');

    final rawDate = s?['tanggal']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      _date = DateTime.tryParse(rawDate);
    }

    final rawTime = s?['waktu']?.toString();
    if (rawTime != null) {
      final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(rawTime);
      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        if (hour < 24 && minute < 60) {
          _time = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1);
    final last = DateTime(now.year + 5);

    var initial = _date ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (selected != null && mounted) {
      setState(() {
        _date = selected;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );

    if (selected != null && mounted) {
      setState(() {
        _time = selected;
        _timeError = null;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final formOk = _formKey.currentState!.validate();
    final dateOk = _date != null;
    final timeOk = _time != null;

    setState(() {
      _dateError = dateOk ? null : 'Pilih tanggal kegiatan.';
      _timeError = timeOk ? null : 'Pilih waktu kegiatan.';
      if (!formOk || !dateOk || !timeOk) _autoValidate = true;
    });

    if (!formOk || !dateOk || !timeOk) return;

    setState(() => _isSaving = true);

    final date = _date!;
    final data = {
      'tanggal':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'waktu': _formatTime(_time!),
      'lokasi': _locationCtrl.text.trim(),
    };

    try {
      final supabase = Supabase.instance.client;

      if (widget.schedule == null) {
        await supabase.from('jadwal').insert(data);
      } else {
        await supabase
            .from('jadwal')
            .update(data)
            .eq('id', widget.schedule!['id']);
      }

      if (!mounted) return;

      final tanggal = tanggalLengkap(date);
      Navigator.pop(
        context,
        _isEdit
            ? 'Perubahan jadwal $tanggal disimpan.'
            : 'Jadwal $tanggal disimpan.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = friendlyError(
          error,
          fallback:
              'Jadwal belum tersimpan. Periksa koneksi internet, lalu coba lagi.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kepala
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
                    child: Semantics(
                      header: true,
                      child: Text(
                        _isEdit ? 'Ubah jadwal' : 'Tambah jadwal',
                        style: AppText.title,
                      ),
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

            // Isi
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
                      Text('Tanggal', style: AppText.label),
                      const SizedBox(height: 6),
                      AppPickerTile(
                        icon: Icons.calendar_month_outlined,
                        value: _date == null
                            ? 'Pilih tanggal'
                            : tanggalLengkap(_date!),
                        isPlaceholder: _date == null,
                        semanticLabel: _date == null
                            ? 'Tanggal belum dipilih. Pilih tanggal'
                            : 'Tanggal ${tanggalLengkap(_date!)}. Ubah tanggal',
                        onTap: _pickDate,
                      ),
                      if (_dateError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _dateError!,
                          style: AppText.caption.copyWith(
                            color: AppStatus.danger.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.lg),

                      Text('Waktu', style: AppText.label),
                      const SizedBox(height: 6),
                      AppPickerTile(
                        icon: Icons.access_time_rounded,
                        value: _time == null
                            ? 'Pilih waktu'
                            : 'Pukul ${_formatTime(_time!)}',
                        isPlaceholder: _time == null,
                        semanticLabel: _time == null
                            ? 'Waktu belum dipilih. Pilih waktu'
                            : 'Waktu pukul ${_formatTime(_time!)}. Ubah waktu',
                        onTap: _pickTime,
                      ),
                      if (_timeError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _timeError!,
                          style: AppText.caption.copyWith(
                            color: AppStatus.danger.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.lg),

                      AppTextField(
                        label: 'Lokasi',
                        controller: _locationCtrl,
                        hint: 'Nama tempat kegiatan',
                        prefixIcon: Icons.location_on_outlined,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        validator: (v) => validateRequired(v, 'Lokasi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Kaki
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
                      label: _isEdit ? 'Simpan perubahan' : 'Simpan jadwal',
                      onPressed: _save,
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