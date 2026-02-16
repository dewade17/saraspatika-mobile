import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saraspatika/feature/agenda/data/dto/agenda.dart';
import 'package:saraspatika/feature/agenda/screens/widget/agenda_action_buttons.dart';
import 'package:saraspatika/feature/agenda/screens/widget/agenda_bukti_preview.dart';
import 'package:saraspatika/feature/agenda/screens/widget/agenda_info_row.dart';

class AgendaDetailBottomSheet extends StatelessWidget {
  const AgendaDetailBottomSheet({super.key, required this.agenda});

  final Agenda agenda;

  static void show({required BuildContext context, required Agenda agenda}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => AgendaDetailBottomSheet(agenda: agenda),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Detail Agenda',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              AgendaInfoRow(
                icon: Icons.date_range,
                iconColor: Colors.indigo,
                label: 'Tanggal',
                value: DateFormat(
                  'EEEE, dd MMMM yyyy',
                  'id_ID',
                ).format(agenda.tanggal.toLocal()),
              ),
              const SizedBox(height: 8),
              AgendaInfoRow(
                icon: Icons.access_time,
                iconColor: Colors.indigo,
                label: 'Jam Mulai',
                value: DateFormat(
                  'HH:mm',
                  'id_ID',
                ).format(agenda.jamMulai.toLocal()),
              ),
              const SizedBox(height: 8),
              AgendaInfoRow(
                icon: Icons.access_time_filled,
                iconColor: Colors.indigo,
                label: 'Jam Selesai',
                value: DateFormat(
                  'HH:mm',
                  'id_ID',
                ).format(agenda.jamSelesai.toLocal()),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.notes, size: 20, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Deskripsi Pekerjaan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    agenda.deskripsi,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Bukti Pekerjaan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              AgendaBuktiPreview(buktiPendukungUrl: agenda.buktiPendukungUrl),
              const SizedBox(height: 24),
              AgendaActionButtons(
                onEdit: () {
                  Navigator.pop(context);
                },
                onDelete: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
