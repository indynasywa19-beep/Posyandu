class Pemeriksaan {
  Object? id;
  Object anakId;
  String tanggal;
  double beratBadan;
  double tinggiBadan;
  String catatan;

  Pemeriksaan({
    this.id,
    required this.anakId,
    required this.tanggal,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.catatan,
  });

  Map<String, dynamic> toMap() {
    return {
      'anak_id': anakId,
      'tanggal': tanggal,
      'berat_badan': beratBadan,
      'tinggi_badan': tinggiBadan,
      'catatan': catatan,
    };
  }

  factory Pemeriksaan.fromMap(Map<String, dynamic> map) {
    return Pemeriksaan(
      id: map['id'],
      anakId: map['anak_id'] ?? map['anakId'] ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      beratBadan: double.tryParse(
            (map['berat_badan'] ?? map['beratBadan'] ?? 0).toString(),
          ) ??
          0,
      tinggiBadan: double.tryParse(
            (map['tinggi_badan'] ?? map['tinggiBadan'] ?? 0).toString(),
          ) ??
          0,
      catatan: map['catatan']?.toString() ?? '',
    );
  }
}
