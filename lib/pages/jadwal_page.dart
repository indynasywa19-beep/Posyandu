import 'package:flutter/material.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),

      appBar: AppBar(
        title: const Text('Jadwal Posyandu'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal Posyandu',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              'Informasi jadwal kegiatan Posyandu.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // JADWAL UTAMA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2E5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Colors.green,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 15),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Posyandu Bulan Oktober',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              '12 Oktober 2026',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Divider(),

                  const SizedBox(height: 15),

                  const Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey),

                      SizedBox(width: 10),

                      Text('08.00 - 11.00 WIB', style: TextStyle(fontSize: 15)),
                    ],
                  ),

                  const SizedBox(height: 15),

                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.grey),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Posyandu Melati, Balai Warga',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Kegiatan',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // KEGIATAN 1
            _buildKegiatan(
              icon: Icons.monitor_weight_outlined,
              title: 'Penimbangan',
              description: 'Pengukuran berat badan anak.',
            ),

            const SizedBox(height: 12),

            // KEGIATAN 2
            _buildKegiatan(
              icon: Icons.height,
              title: 'Pengukuran Tinggi Badan',
              description: 'Pemantauan pertumbuhan tinggi badan anak.',
            ),

            const SizedBox(height: 12),

            // KEGIATAN 3
            _buildKegiatan(
              icon: Icons.vaccines_outlined,
              title: 'Imunisasi',
              description: 'Pemberian imunisasi sesuai jadwal.',
            ),

            const SizedBox(height: 12),

            // KEGIATAN 4
            _buildKegiatan(
              icon: Icons.medical_services_outlined,
              title: 'Pemeriksaan Kesehatan',
              description: 'Pemeriksaan kondisi kesehatan anak.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKegiatan({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
