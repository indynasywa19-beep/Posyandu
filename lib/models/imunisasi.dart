class Imunisasi {
  Object? id;
  Object anakId;
  String namaVaksin;
  String tanggal;
  String keterangan;

  Imunisasi({
    this.id,
    required this.anakId,
    required this.namaVaksin,
    required this.tanggal,
    required this.keterangan,
  });

  // Mengubah data menjadi Map untuk disimpan ke database
  Map<String, dynamic> toMap() {
    return {
      'anak_id': anakId,
      'nama_vaksin': namaVaksin,
      'tanggal': tanggal,
      'keterangan': keterangan,
    };
  }

  // Mengambil data dari database lalu mengubahnya menjadi object Imunisasi
  factory Imunisasi.fromMap(Map<String, dynamic> map) {
    return Imunisasi(
      id: map['id'],
      anakId: map['anak_id'] ?? map['anakId'] ?? '',
      namaVaksin: map['nama_vaksin'] ?? map['namaVaksin'] ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      keterangan: map['keterangan']?.toString() ?? '',
    );
  }
}
