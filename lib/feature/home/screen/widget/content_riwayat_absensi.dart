import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/feature/home/data/provider/history_kehadiran_provider.dart';
import 'package:saraspatika/feature/home/data/dto/history_kehadiran.dart';

class ContentRiwayatAbsensi extends StatefulWidget {
  const ContentRiwayatAbsensi({super.key});

  @override
  State<ContentRiwayatAbsensi> createState() => _ContentRiwayatAbsensiState();
}

class _ContentRiwayatAbsensiState extends State<ContentRiwayatAbsensi> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryKehadiranProvider>().fetchMyHistory(limit: 7);
    });
  }

  String formatTime(DateTime? dateTime) {
    if (dateTime == null) return "--:--";
    return DateFormat('HH:mm').format(dateTime);
  }

  String formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryKehadiranProvider>();
    final listHistory = historyProvider.history;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "History\nKehadiran",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/data-absensi'),
              child: const Text(
                "View All",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (historyProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (listHistory.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'lib/assets/images/Profile-empty.png',
                      width: 200,
                    ),
                  ),
                  Text(
                    "Belum ada data absensi",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: listHistory
                .map((item) => _buildAttendanceCard(item))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceData item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDate(item.tanggal),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn("Jam Masuk", item.waktuMasuk, Colors.green),
                _buildTimeColumn("Jam Pulang", item.waktuPulang, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String label, DateTime? time, Color color) {
    return Row(
      children: [
        Icon(Icons.location_on, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              formatTime(time),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
