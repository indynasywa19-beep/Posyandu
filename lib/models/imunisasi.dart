class Imunisasi {
  int? id;
  int anakId;
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
      'id': id,
      'anakId': anakId,
      'namaVaksin': namaVaksin,
      'tanggal': tanggal,
      'keterangan': keterangan,
    };
  }

  // Mengambil data dari database lalu mengubahnya menjadi object Imunisasi
  factory Imunisasi.fromMap(Map<String, dynamic> map) {
    return Imunisasi(
      id: map['id'],
      anakId: map['anakId'],
      namaVaksin: map['namaVaksin'],
      tanggal: map['tanggal'],
      keterangan: map['keterangan'] ?? '',
    );
  }
}
