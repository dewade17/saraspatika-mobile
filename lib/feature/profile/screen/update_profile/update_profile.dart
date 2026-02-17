import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/profile/screen/update_profile/widget/content_update_profile.dart';

class UpdateProfile extends StatelessWidget {
  const UpdateProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: AppColors.backgroundColor,
        title: const Text(
          'Perbarui Profil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Container(
        color: AppColors.secondaryBackgroundColor,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ContentUpdateProfile(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
