import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/agenda/data/dto/agenda.dart';
import 'package:saraspatika/feature/agenda/data/provider/agenda_provider.dart';
import 'package:saraspatika/feature/agenda/screens/form_agenda/form_agenda_screen.dart';
import 'package:saraspatika/feature/agenda/screens/widget/agenda_detail_bottom_sheet.dart';
import 'package:saraspatika/feature/agenda/screens/widget/agenda_list_item_card.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';

class AgendaHomeScreen extends StatefulWidget {
  const AgendaHomeScreen({super.key});

  @override
  State<AgendaHomeScreen> createState() => _AgendaHomeScreenState();
}

class _AgendaHomeScreenState extends State<AgendaHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgendaProvider>().fetchAgendaListByCurrentUser();
    });
  }

  Future<void> _refreshAgenda() {
    return context.read<AgendaProvider>().fetchAgendaListByCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().me;
    final String titleSuffix = user?.role.toUpperCase() == 'GURU'
        ? 'Mengajar'
        : 'Kerja';

    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.backgroundColor,
        title: Text(
          'Agenda $titleSuffix',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body: Consumer<AgendaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.agendaList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.agendaList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshAgenda,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.agendaList.isEmpty) {
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
                  Text('Belum ada agenda.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAgenda,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.agendaList.length,
              itemBuilder: (context, index) {
                final Agenda agenda = provider.agendaList[index];

                return AgendaListItemCard(
                  agenda: agenda,
                  onTap: () => AgendaDetailBottomSheet.show(
                    context: context,
                    agenda: agenda,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final isCreated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const FormAgendaScreen()),
          );

          if (isCreated == true && mounted) {
            await _refreshAgenda();
          }
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
