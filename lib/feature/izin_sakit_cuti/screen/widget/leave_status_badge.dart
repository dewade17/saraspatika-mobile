import 'package:flutter/material.dart';

class LeaveStatusBadge extends StatelessWidget {
  final String? status;

  const LeaveStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        (status ?? 'MENUNGGU').toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: _statusColor(status),
    );
  }

  Color _statusColor(String? status) {
    final s = (status ?? 'MENUNGGU').toUpperCase();
    if (s == 'MENUNGGU') return Colors.orange;
    if (s == 'SETUJU') return Colors.green;
    if (s == 'DITOLAK') return Colors.redAccent;
    return Colors.blueGrey;
  }
}
