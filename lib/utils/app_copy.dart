import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sapaan sesuai jam. Dipakai di beranda menggantikan "Selamat pagi" tetap.
String greetingForHour(int hour) {
  if (hour >= 4 && hour < 11) return 'Selamat pagi';
  if (hour >= 11 && hour < 15) return 'Selamat siang';
  if (hour >= 15 && hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String greetingNow() => greetingForHour(DateTime.now().hour);

/// Ambil satu atau dua huruf awal dari nama. Mengembalikan '?' bila kosong.
String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

/// Catat error teknis ke log tanpa menampilkannya ke pengguna.
void logError(Object? error, [String where = '']) {
  debugPrint('Error${where.isEmpty ? '' : ' ($where)'}: $error');
}

/// Nama yang ditampilkan untuk pengguna. Memeriksa kunci metadata yang
/// dipakai aplikasi: `display_name` (diubah dari halaman profil),
/// `full_name`, dan `nama` (diisi saat daftar). Bila semuanya kosong,
/// mengembalikan [fallback].
String displayNameFromUser(User? user, {required String fallback}) {
  final meta = user?.userMetadata;
  for (final key in const ['display_name', 'full_name', 'nama']) {
    final value = meta?[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return fallback;
}

const _namaHari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Contoh: "November" (1 sampai 12).
String bulanLengkap(int month) => _namaBulan[month - 1];

/// Contoh: "Nov" (tiga huruf pertama nama bulan, 1 sampai 12).
String bulanSingkat(int month) => _namaBulan[month - 1].substring(0, 3);

/// Contoh: "Senin, 9 November 2026".
String tanggalLengkap(DateTime date) {
  return '${_namaHari[date.weekday - 1]}, ${date.day} '
      '${_namaBulan[date.month - 1]} ${date.year}';
}

/// Ubah error teknis menjadi kalimat yang bisa dipahami pengguna.
///
/// Pesan asli tidak ditampilkan, hanya dicatat lewat [debugPrint].
/// Setiap pesan menjelaskan apa yang terjadi dan apa yang bisa dilakukan.
String friendlyError(
  Object error, {
  String fallback = 'Terjadi masalah. Coba lagi sebentar lagi.',
}) {
  debugPrint('Error: $error');

  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email atau kata sandi tidak cocok. Periksa lalu coba lagi.';
    }
    if (m.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Buka kotak masuk email Anda dan ikuti tautan konfirmasinya.';
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Coba masuk, atau gunakan email lain.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat, lalu coba lagi.';
    }
    if (m.contains('password')) {
      return 'Kata sandi belum memenuhi syarat. Coba kata sandi yang lebih panjang atau lebih kuat.';
    }
    return fallback;
  }

  if (error is PostgrestException) {
    return 'Data belum bisa diproses. Coba lagi sebentar lagi.';
  }

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('ClientException') ||
      text.contains('TimeoutException')) {
    return 'Tidak ada koneksi internet. Periksa jaringan, lalu coba lagi.';
  }

  return fallback;
}
