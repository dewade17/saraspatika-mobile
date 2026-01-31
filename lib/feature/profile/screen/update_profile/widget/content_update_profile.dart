import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';
import 'package:saraspatika/feature/profile/data/dto/user.dart';
import 'package:saraspatika/feature/profile/data/provider/user_profile_provider.dart';

class ContentUpdateProfile extends StatefulWidget {
  const ContentUpdateProfile({super.key});

  @override
  State<ContentUpdateProfile> createState() => _ContentUpdateProfileState();
}

class _ContentUpdateProfileState extends State<ContentUpdateProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();

  final AppFilePickerController _photoController = AppFilePickerController();
  UserData? _loadedUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nipController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profileProvider = context.read<UserProfileProvider>();
    try {
      await profileProvider.fetchCurrentUser();
    } catch (_) {}
  }

  Future<void> _pickProfilePhoto() async {
    await _photoController.pickProfilePhoto(
      context,
      allowCamera: true,
      allowGallery: true,
      compressCameraImage: true,
      cameraLabel: 'Kamera',
      galleryLabel: 'Galeri',
      hapticFeedback: true,
    );
  }

  void _applyUser(UserData user) {
    _loadedUser = user;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.nomorHandphone ?? '';
    _nipController.text = user.nip ?? '';
  }

  Future<void> _handleSave() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data yang wajib diisi.')),
      );
      return;
    }

    final profileProvider = context.read<UserProfileProvider>();

    try {
      await profileProvider.updateCurrentUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        nomorHandphone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        nip: _nipController.text.trim().isEmpty
            ? null
            : _nipController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan berhasil disimpan.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileProvider.errorMessage ?? 'Gagal menyimpan perubahan.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final user = profileProvider.selectedUser;
    final error = profileProvider.errorMessage;

    if (error != null && error.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        profileProvider.clearError();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      });
    }

    if (user != null && user != _loadedUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyUser(user);
      });
    }

    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ValueListenableBuilder<List<AppPickedFile>>(
                  valueListenable: _photoController,
                  builder: (context, files, _) {
                    final picked = files.isNotEmpty ? files.first : null;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: (picked != null && picked.isImage)
                            ? Image.file(
                                picked.file,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[400],
                                  );
                                },
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: _pickProfilePhoto,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _nameController,
            label: 'Nama',
            hintText: 'Masukkan nama',
            leadingIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Nama wajib diisi.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Masukkan email',
            leadingIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Email wajib diisi.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _phoneController,
            label: 'No HP',
            hintText: 'Masukkan nomor HP',
            leadingIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _nipController,
            label: 'NIP',
            hintText: 'Masukkan NIP',
            leadingIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Simpan Perubahan',
            fullWidth: true,
            onPressed: profileProvider.isLoading ? null : _handleSave,
          ),
        ],
      ),
    );
  }
}
