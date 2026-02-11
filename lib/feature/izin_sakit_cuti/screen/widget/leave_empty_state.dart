import 'package:flutter/material.dart';

class LeaveEmptyState extends StatelessWidget {
  const LeaveEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 200),
          SizedBox(
            width: 200,
            height: 200,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'lib/assets/images/Empty-data.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Text(
            'Saat Ini Kamu Tidak Memiliki Pengajuan.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
