import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:saraspatika/core/constanta/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Dummy user (UI-only)
  final _ProfileUserUiModel _user = const _ProfileUserUiModel(
    nama: 'I Putu Hendy Pradika, S.Pd',
    email: 'hendy@example.com',
    noHp: '',
    nip: '',
    // isi base64 image kalau mau test (boleh dengan prefix data:image/...;base64,)
    fotoProfil: '',
  );

  Future<void> _fakeRefresh() async {
    // UI-only refresh palsu
    await Future<void>.delayed(const Duration(milliseconds: 700));
    setState(() {});
  }

  Uint8List? _tryDecodeBase64Image(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final isBase64Image = trimmed.startsWith('data:image');
    if (!isBase64Image) return null;

    try {
      final cleaned = trimmed.split(',').last;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _tryDecodeBase64Image(_user.fotoProfil);

    return Scaffold(
      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil'),
        backgroundColor: AppColors.primaryColor,
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
                  backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                  child: bytes == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionHeader("Informasi Pribadi"),
              _buildInfoTile(Icons.person, _user.nama),
              _buildInfoTile(Icons.email, _user.email),
              _buildInfoTile(
                Icons.phone,
                (_user.noHp?.isNotEmpty == true)
                    ? _user.noHp!
                    : "Lengkapi nomor telepon",
              ),
              _buildInfoTile(
                Icons.badge,
                (_user.nip?.isNotEmpty == true)
                    ? _user.nip!
                    : "Lengkapi NIP Anda",
              ),

              const SizedBox(height: 24),

              _buildSectionHeader("Pengaturan"),
              _buildActionTile(Icons.face, "Registrasi Wajah", () {
                // UI-only placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registrasi Wajah (UI dummy)')),
                );
              }),
              _buildActionTile(Icons.warning, "Absensi Darurat", () {
                // UI-only placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Absensi Darurat (UI dummy)')),
                );
              }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // UI-only placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit Profil (UI dummy)')),
          );
        },
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
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(value),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.settings, color: Colors.orange),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// =====================
// UI Model (Dummy)
// =====================
class _ProfileUserUiModel {
  final String nama;
  final String email;
  final String? noHp;
  final String? nip;
  final String? fotoProfil; // base64 image optional

  const _ProfileUserUiModel({
    required this.nama,
    required this.email,
    this.noHp,
    this.nip,
    this.fotoProfil,
  });
}
