import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _fakeRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() {});
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const String namaUser = 'I Putu Hendy Pradika, S.Pd';
    const String emailUser = 'hendy@example.com';
    const String noHpUser = '081234567890';
    const String nipUser = '199201012024011001';

    return Scaffold(
      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fakeRefresh,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Informasi Pribadi"),
              _buildInfoTile(Icons.person, namaUser),
              _buildInfoTile(Icons.email, emailUser),
              _buildInfoTile(Icons.phone, noHpUser),
              _buildInfoTile(Icons.badge, nipUser),
              const SizedBox(height: 24),
              _buildSectionHeader("Pengaturan"),
              _buildActionTile(Icons.face, "Registrasi Wajah", () {
                _showSnackBar(context, 'Registrasi Wajah (UI dummy)');
              }),
              _buildActionTile(Icons.warning, "Absensi Darurat", () {
                _showSnackBar(context, 'Absensi Darurat (UI dummy)');
              }),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSnackBar(context, 'Edit Profil (UI dummy)'),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
