import 'package:flutter/material.dart';
import 'package:saraspatika/feature/request_wajah/screen/home_request_wajah.dart';

class SectionSettingScreen extends StatefulWidget {
  const SectionSettingScreen({super.key});

  @override
  State<SectionSettingScreen> createState() => _SectionSettingScreenState();
}

class _SectionSettingScreenState extends State<SectionSettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10, top: 20),
          child: Text(
            "PENGATURAN",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0.5,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.face, color: Colors.orange),
            title: const Text(
              "Registrasi Wajah",
              style: TextStyle(fontSize: 15),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
            onTap: () => (Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeRequestWajah()),
            )),
          ),
        ),
      ],
    );
  }
}
