import 'package:flutter/material.dart';

class LeaveStatusBadge extends StatelessWidget {
  final String? status;

  const LeaveStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        (status ?? 'PENDING').toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: _statusColor(status),
    );
  }

  Color _statusColor(String? status) {
    final s = (status ?? 'PENDING').toUpperCase();
    if (s == 'PENDING') return Colors.orange;
    if (s == 'APPROVED') return Colors.green;
    if (s == 'REJECTED') return Colors.redAccent;
    return Colors.blueGrey;
  }
}
  