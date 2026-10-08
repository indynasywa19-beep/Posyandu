import 'package:flutter/material.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF7),

      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // FOTO PROFIL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2E5),
                      borderRadius: BorderRadius.circular(45),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 55,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Indy Nasywa',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Orang Tua / Wali',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // INFORMASI AKUN
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Informasi Akun',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            _buildMenu(
              icon: Icons.person_outline,
              title: 'Nama Lengkap',
              subtitle: 'Indy Nasywa',
            ),

            const SizedBox(height: 10),

            _buildMenu(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'indy@email.com',
            ),

            const SizedBox(height: 10),

            _buildMenu(
              icon: Icons.phone_outlined,
              title: 'Nomor Telepon',
              subtitle: '08xxxxxxxxxx',
            ),

            const SizedBox(height: 20),

            // DATA ANAK
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Data Anak',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            _buildMenu(
              icon: Icons.child_care,
              title: 'Aisyah Putri',
              subtitle: '3 Tahun • Perempuan',
            ),

            const SizedBox(height: 20),

            // TOMBOL EDIT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // TOMBOL LOGOUT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 3),

                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
