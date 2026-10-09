class Anak {
  Object? id;
  String nama;
  String nik;
  String tanggalLahir;
  String jenisKelamin;

  Anak({
    this.id,
    required this.nama,
    required this.nik,
    required this.tanggalLahir,
    required this.jenisKelamin,
  });

  // Mengubah data Anak menjadi Map
  // Nanti dipakai untuk menyimpan ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nik': nik,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
    };
  }

  // Mengubah data dari database menjadi object Anak
  factory Anak.fromMap(Map<String, dynamic> map) {
    return Anak(
      id: map['id'],
      nama: map['nama']?.toString() ?? '',
      nik: map['nik']?.toString() ?? '',
      tanggalLahir:
          (map['tanggal_lahir'] ?? map['tanggalLahir'])?.toString() ?? '',
      jenisKelamin:
          (map['jenis_kelamin'] ?? map['jenisKelamin'])?.toString() ?? '',
    );
  }
}