import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataAnakPage extends StatefulWidget {
  final bool isKader;

  const DataAnakPage({super.key, this.isKader = false});

  @override
  State<DataAnakPage> createState() => _DataAnakPageState();
}

class _DataAnakPageState extends State<DataAnakPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  String? _loadError;

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
      final List<Map<String, dynamic>> rows;
      if (widget.isKader) {
        rows = await _supabase.from('anak').select().order('nama');
      } else {
        rows = await _supabase
            .from('anak')
            .select()
            .eq('user_id', user!.id)
            .order('nama');
      }
      if (!mounted) return;
      setState(() {
        _children = rows;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat data anak: $error';
        _isLoading = false;
      });
    }
  }

  void _showForm({Map<String, dynamic>? child}) {
    final nameController = TextEditingController(
      text: child?['nama'] as String? ?? '',
    );
    final nikController = TextEditingController(
      text: child?['nik'] as String? ?? '',
    );
    final birthDateController = TextEditingController(
      text: child?['tanggal_lahir'] as String? ?? '',
    );
    var gender = child?['jenis_kelamin'] as String? ?? 'Perempuan';
    var nikErrorText = _nikError(nikController.text);
    var isSaving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canSave =
              nameController.text.trim().isNotEmpty &&
              RegExp(r'^\d{16}$').hasMatch(nikController.text) &&
              birthDateController.text.isNotEmpty &&
              !isSaving;

          return AlertDialog(
            title: Text(child == null ? 'Tambah Data Anak' : 'Edit Data Anak'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Anak',
                      prefixIcon: Icon(Icons.child_care_outlined),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nikController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: InputDecoration(
                      labelText: 'NIK',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      errorText: nikErrorText,
                      counterText: '${nikController.text.length}/16',
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        nikErrorText = _nikError(value);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: birthDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Lahir',
                      hintText: 'Pilih tanggal lahir',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final parsedDate = DateTime.tryParse(
                        birthDateController.text,
                      );
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: parsedDate ?? now,
                        firstDate: DateTime(1900),
                        lastDate: now,
                      );
                      if (picked == null) return;
                      setDialogState(() {
                        birthDateController.text =
                            '${picked.year.toString().padLeft(4, '0')}-'
                            '${picked.month.toString().padLeft(2, '0')}-'
                            '${picked.day.toString().padLeft(2, '0')}';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
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
                      if (value != null) {
                        setDialogState(() => gender = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: canSave
                    ? () async {
                        final user = _supabase.auth.currentUser;
                        if (user == null) {
                          _showMessage(
                            'Sesi login berakhir. Silakan masuk kembali.',
                            isError: true,
                          );
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        try {
                          final data = <String, dynamic>{
                            'nama': nameController.text.trim(),
                            'nik': nikController.text,
                            'tanggal_lahir': birthDateController.text,
                            'jenis_kelamin': gender,
                          };
                          if (child == null) {
                            await _supabase.from('anak').insert({
                              ...data,
                              'user_id': user.id,
                            });
                          } else {
                            await _supabase
                                .from('anak')
                                .update(data)
                                .eq('id', child['id']);
                          }
                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          _showMessage('Data anak berhasil disimpan.');
                          await _loadChildren();
                        } catch (error) {
                          if (!mounted || !dialogContext.mounted) return;
                          setDialogState(() => isSaving = false);
                          _showMessage(
                            'Gagal menyimpan data anak: $error',
                            isError: true,
                          );
                        }
                      }
                    : null,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      nameController.dispose();
      nikController.dispose();
      birthDateController.dispose();
    });
  }

  String? _nikError(String nik) {
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      return 'NIK harus terdiri dari 16 digit angka';
    }
    return null;
  }

  Future<void> _deleteChild(Map<String, dynamic> child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data anak?'),
        content: Text('Data ${child['nama']} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _supabase.from('anak').delete().eq('id', child['id']);
      _showMessage('Data anak berhasil dihapus.');
      await _loadChildren();
    } catch (error) {
      _showMessage('Gagal menghapus data anak: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isKader
        ? const Color(0xFF173B72)
        : const Color(0xFF13835F);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.isKader ? 'Monitoring Anak' : 'Data Anak'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Anak'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.cloud_off_outlined, size: 48, color: color),
                  const SizedBox(height: 12),
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadChildren,
                    child: const Text('Coba lagi'),
                  ),
                ],
              )
            : _children.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 70),
                  Icon(Icons.child_care_outlined, size: 56, color: color),
                  const SizedBox(height: 16),
                  Text(
                    widget.isKader
                        ? 'Belum ada data anak di Posyandu.'
                        : 'Data Anak Kosong',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isKader
                        ? 'Data yang didaftarkan orang tua akan tampil di sini.'
                        : 'Tambahkan identitas anak Anda terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey.shade600),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];
                  final name = child['nama'] as String? ?? 'Tanpa nama';
                  final gender = child['jenis_kelamin'] as String? ?? '-';
                  final birthDate = child['tanggal_lahir'] as String? ?? '-';
                  final nik = child['nik'] as String? ?? '-';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.1),
                        foregroundColor: color,
                        child: const Icon(Icons.child_care_rounded),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('$gender • Lahir $birthDate\nNIK: $nik'),
                      ),
                      isThreeLine: true,
                      trailing: widget.isKader
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _showForm(child: child),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Hapus',
                                  onPressed: () => _deleteChild(child),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
