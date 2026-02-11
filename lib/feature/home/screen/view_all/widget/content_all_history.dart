import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/feature/home/data/dto/history_kehadiran.dart';
import 'package:saraspatika/feature/home/data/provider/history_kehadiran_provider.dart';
import 'package:saraspatika/feature/home/screen/view_all/widget/calendar_kehadiran.dart';
// Import table_calendar untuk menggunakan fungsi isSameDay
import 'package:table_calendar/table_calendar.dart';

class ContentAllHistory extends StatefulWidget {
  const ContentAllHistory({super.key});

  @override
  State<ContentAllHistory> createState() => _ContentAllHistoryState();
}

class _ContentAllHistoryState extends State<ContentAllHistory> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchDataForMonth(_focusedMonth);
  }

  void _fetchDataForMonth(DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final dateFormat = DateFormat('yyyy-MM-dd');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryKehadiranProvider>().fetchMyHistory(
        startDate: dateFormat.format(startDate),
        endDate: dateFormat.format(endDate),
      );
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return "--:--";
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryKehadiranProvider>();
    final listHistory = historyProvider.history;

    final filteredHistory = _selectedDate == null
        ? listHistory
        : listHistory
              .where((item) => isSameDay(item.tanggal, _selectedDate))
              .toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: CalendarKehadiran<AttendanceData>(
            items: listHistory,
            selectedDay: _selectedDate,
            getStartDate: (item) => item.tanggal,
            getEndDate: (item) => item.tanggal,
            onMonthChanged: (month) {
              setState(() {
                _focusedMonth = month;
                _selectedDate = null;
              });
              _fetchDataForMonth(month);
            },
            onDaySelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        if (historyProvider.isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )
        else if (filteredHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _selectedDate == null
                  ? "Tidak ada data absensi pada bulan ini."
                  : "Tidak ada data absensi pada tanggal ${DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!)}.",
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filteredHistory.length,
            itemBuilder: (context, index) {
              final item = filteredHistory[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE, dd MMMM yyyy',
                          'id_ID',
                        ).format(item.tanggal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn(
                            Icons.location_on,
                            Colors.green,
                            "Masuk",
                            _formatTime(item.waktuMasuk),
                          ),
                          _buildInfoColumn(
                            Icons.location_on,
                            Colors.red,
                            "Pulang",
                            _formatTime(item.waktuPulang),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // Widget helper untuk merapikan kode UI Row
  Widget _buildInfoColumn(
    IconData icon,
    Color color,
    String label,
    String time,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
