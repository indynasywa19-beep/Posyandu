class Pemeriksaan {
  int? id;
  int anakId;
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
      'id': id,
      'anakId': anakId,
      'tanggal': tanggal,
      'beratBadan': beratBadan,
      'tinggiBadan': tinggiBadan,
      'catatan': catatan,
    };
  }

  factory Pemeriksaan.fromMap(Map<String, dynamic> map) {
    return Pemeriksaan(
      id: map['id'],
      anakId: map['anakId'],
      tanggal: map['tanggal'],
      beratBadan: map['beratBadan'],
      tinggiBadan: map['tinggiBadan'],
      catatan: map['catatan'],
    );
  }
}
