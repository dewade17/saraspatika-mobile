import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/profile/screen/update_profile/update_profile.dart';
import 'package:saraspatika/feature/profile/screen/widget/section_setting_screen.dart';

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
              const Padding(
                padding: EdgeInsets.only(bottom: 10, top: 20),
                child: Text(
                  "INFORMASI PRIBADI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              infoCard(Icons.person, namaUser),
              infoCard(Icons.email, emailUser),
              infoCard(Icons.phone, noHpUser),
              infoCard(Icons.badge, nipUser),
              const SizedBox(height: 24),

              SectionSettingScreen(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpdateProfile()),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget infoCard(IconData icon, String value) {
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
}
