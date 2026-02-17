import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';

class AgendaActionButtons extends StatelessWidget {
  const AgendaActionButtons({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.edit, color: AppColors.backgroundColor),
          label: const Text(
            "Edit",
            style: TextStyle(color: AppColors.backgroundColor),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onEdit,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete, color: AppColors.backgroundColor),
          label: const Text(
            "Hapus",
            style: TextStyle(color: AppColors.backgroundColor),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
