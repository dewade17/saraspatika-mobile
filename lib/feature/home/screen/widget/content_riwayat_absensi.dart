import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Tambahkan import provider
import 'package:saraspatika/feature/home/data/provider/history_kehadiran_provider.dart'; // Import provider Anda

class ContentRiwayatAbsensi extends StatefulWidget {
  const ContentRiwayatAbsensi({super.key});

  @override
  State<ContentRiwayatAbsensi> createState() => _ContentRiwayatAbsensiState();
}

class _ContentRiwayatAbsensiState extends State<ContentRiwayatAbsensi> {
  late final DateTime now;
  late final String tanggalFormatted;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    tanggalFormatted = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    // Memicu pengambilan data saat widget dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryKehadiranProvider>().fetchMyHistory(limit: 1);
    });
  }

  // Fungsi helper untuk memformat waktu dari DateTime
  String formatTime(DateTime? dateTime) {
    if (dateTime == null) return "--:--";
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan data pada provider
    final historyProvider = context.watch<HistoryKehadiranProvider>();

    // Mengambil data terbaru jika tersedia
    final latestAttendance = historyProvider.history.isNotEmpty
        ? historyProvider.history.first
        : null;

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
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tanggalFormatted,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Jam Masuk",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              // Data dinamis dari provider
                              formatTime(latestAttendance?.waktuMasuk),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Jam Pulang",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              // Data dinamis dari provider
                              formatTime(latestAttendance?.waktuPulang),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
