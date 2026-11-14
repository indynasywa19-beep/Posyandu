// Validator form. Mengembalikan null bila isian benar, atau kalimat
// yang menjelaskan apa yang perlu diperbaiki.

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName wajib diisi.';
  }
  return null;
}

String? validateEmail(String? value) {
  final required = validateRequired(value, 'Email');
  if (required != null) return required;
  if (!_emailPattern.hasMatch(value!.trim())) {
    return 'Format email belum benar. Contoh: nama@email.com';
  }
  return null;
}
