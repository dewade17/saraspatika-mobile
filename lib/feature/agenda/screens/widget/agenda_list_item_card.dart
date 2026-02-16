import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saraspatika/feature/agenda/data/dto/agenda.dart';

class AgendaListItemCard extends StatelessWidget {
  const AgendaListItemCard({
    super.key,
    required this.agenda,
    required this.onTap,
  });

  final Agenda agenda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'dd MMM yyyy',
                      'id_ID',
                    ).format(agenda.tanggal.toLocal()),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('HH:mm', 'id_ID').format(agenda.jamMulai.toLocal())} - ${DateFormat('HH:mm', 'id_ID').format(agenda.jamSelesai.toLocal())}',
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
