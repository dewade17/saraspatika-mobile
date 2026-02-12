import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/agenda/screens/agenda_ui_data.dart';
import 'package:saraspatika/feature/agenda/screens/form_agenda/form_agenda_screen.dart';
import 'package:saraspatika/feature/agenda/screens/widget/agenda_detail_bottom_sheet.dart';
import 'package:saraspatika/feature/agenda/screens/widget/agenda_list_item_card.dart';

class AgendaHomeScreen extends StatelessWidget {
  const AgendaHomeScreen({super.key});

  static final List<AgendaUiData> _agendas = [
    AgendaUiData(
      agendaId: 'AGD-001',
      createdAt: DateTime(2026, 2, 10, 9, 30),
      tanggal: DateTime(2026, 2, 10),
      jamMulai: DateTime(2026, 2, 10, 8, 0),
      jamSelesai: DateTime(2026, 2, 10, 10, 0),
      deskripsiPekerjaan: 'Mengajar Matematika kelas X - Bab Trigonometri.',
      buktiKind: AgendaBuktiKind.image,
    ),
    AgendaUiData(
      agendaId: 'AGD-002',
      createdAt: DateTime(2026, 2, 11, 13, 0),
      tanggal: DateTime(2026, 2, 11),
      jamMulai: DateTime(2026, 2, 11, 10, 30),
      jamSelesai: DateTime(2026, 2, 11, 12, 0),
      deskripsiPekerjaan: 'Rapat kurikulum & evaluasi pembelajaran.',
      buktiKind: AgendaBuktiKind.pdf,
    ),
    AgendaUiData(
      agendaId: 'AGD-003',
      createdAt: DateTime(2026, 2, 12, 8, 0),
      tanggal: DateTime(2026, 2, 12),
      jamMulai: DateTime(2026, 2, 12, 13, 0),
      jamSelesai: DateTime(2026, 2, 12, 14, 30),
      deskripsiPekerjaan: 'Membuat soal latihan dan pembahasan untuk siswa.',
      buktiKind: AgendaBuktiKind.none,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Mengajar'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: _agendas.isEmpty
          ? const Center(child: Text('Belum ada agenda.'))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _agendas.length,
              itemBuilder: (context, index) {
                final agenda = _agendas[index];

                return AgendaListItemCard(
                  agenda: agenda,
                  onTap: () => AgendaDetailBottomSheet.show(
                    context: context,
                    agenda: agenda,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const FormAgendaScreen()),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
