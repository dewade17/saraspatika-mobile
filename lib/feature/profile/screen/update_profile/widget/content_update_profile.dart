import 'dart:io';

import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nipController.dispose();
    _photoController.dispose();
    super.dispose();
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

  void _handleSave() {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data yang wajib diisi.')),
      );
      return;
    }

    // TODO: sambungkan ke provider/repository update profil.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan disimpan (dummy).')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _handleSave,
          ),
        ],
      ),
    );
  }
}
