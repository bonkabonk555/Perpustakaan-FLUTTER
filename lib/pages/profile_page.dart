import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String nama;
  final String kelas;
  final String nisn;
  final String alamat;
  final String noHp;

  const ProfilePage({
    super.key,
    required this.nama,
    required this.kelas,
    required this.nisn,
    required this.alamat,
    required this.noHp,
  });

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withOpacity(0.85)),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Anggota'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [cs.primary.withOpacity(0.35), const Color(0xFF0E1626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFF101827),
                  backgroundImage: AssetImage(
                    'assets/images/est supha icon.jpg',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelas $kelas • NISN $nisn',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _infoTile(icon: Icons.person_outline, title: 'Nama', value: nama),
          _infoTile(icon: Icons.class_outlined, title: 'Kelas', value: kelas),
          _infoTile(icon: Icons.badge_outlined, title: 'NISN', value: nisn),
          _infoTile(icon: Icons.home_outlined, title: 'Alamat', value: alamat),
          _infoTile(
            icon: Icons.phone_outlined,
            title: 'No Telepon',
            value: noHp,
          ),

          const SizedBox(height: 6),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: cs.primary.withOpacity(0.7)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }
}
