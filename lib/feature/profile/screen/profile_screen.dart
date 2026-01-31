import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/profile/data/provider/user_profile_provider.dart';
import 'package:saraspatika/feature/profile/screen/update_profile/update_profile.dart';
import 'package:saraspatika/feature/profile/screen/widget/section_setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    try {
      await context.read<UserProfileProvider>().fetchCurrentUser();
    } catch (_) {}
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final user = profileProvider.selectedUser;

    final String namaUser = user?.name ?? '-';
    final String emailUser = user?.email ?? '-';
    final String noHpUser = user?.nomorHandphone ?? '-';
    final String nipUser = user?.nip ?? '-';

    final error = profileProvider.errorMessage;
    if (error != null && error.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        profileProvider.clearError();
        _showSnackBar(context, error);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primaryColor, width: 2),
                  ),
                  child: ClipOval(
                    child:
                        (user?.fotoProfilUrl != null &&
                            user!.fotoProfilUrl!.trim().isNotEmpty)
                        ? Image.network(
                            user.fotoProfilUrl!,
                            fit: BoxFit.cover,
                            // Menangani jika URL bukan gambar atau error 404
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 80,
                            color: AppColors.primaryColor,
                          ),
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
              const SectionSettingScreen(),
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
