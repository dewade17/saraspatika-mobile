import 'package:flutter/material.dart';

class HeaderUserAppbar extends StatefulWidget {
  const HeaderUserAppbar({super.key});

  @override
  State<HeaderUserAppbar> createState() => _HeaderUserAppbarState();
}

class DummyUser {
  final String name;
  final String? fotoProfil;

  const DummyUser({required this.name, this.fotoProfil});
}

class _HeaderUserAppbarState extends State<HeaderUserAppbar> {
  // Dummy user
  final DummyUser _user = const DummyUser(
    name: 'I Putu Hendy Pradika, S.Pd',
    fotoProfil: '',
  );

  @override
  Widget build(BuildContext context) {
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
        Text(
          _user.name,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
