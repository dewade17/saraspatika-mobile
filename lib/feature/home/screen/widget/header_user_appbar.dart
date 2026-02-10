import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/feature/profile/data/provider/user_profile_provider.dart';

class HeaderUserAppbar extends StatefulWidget {
  const HeaderUserAppbar({super.key});

  @override
  State<HeaderUserAppbar> createState() => _HeaderUserAppbarState();
}

class _HeaderUserAppbarState extends State<HeaderUserAppbar> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final user = profileProvider.selectedUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat Datang',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          user?.name ?? 'Memuat nama...',
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.nip ?? '',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
