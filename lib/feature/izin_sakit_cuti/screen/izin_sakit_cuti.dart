import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/screen/form_tambah_pengajuan/pengajuan_screen.dart';

import 'widget/leave_card.dart';
import 'widget/leave_detail_sheet.dart';
import 'widget/leave_empty_state.dart';
import 'widget/leave_models.dart';

class IzinSakitCuti extends StatefulWidget {
  const IzinSakitCuti({super.key});

  @override
  State<IzinSakitCuti> createState() => _IzinSakitCutiState();
}

class _IzinSakitCutiState extends State<IzinSakitCuti> {
  bool _isLoading = false;
  String? _errorMessage;

  final List<LeaveRequestUiModel> _requests = [
    LeaveRequestUiModel(
      leaveId: '1',
      jenisIzin: 'Sakit',
      alasan: 'Demam tinggi dan butuh istirahat.',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 1)),
      tanggalSelesai: DateTime.now(),
      status: 'PENDING',
      bukti: BuktiKind.image,
    ),
    LeaveRequestUiModel(
      leaveId: '2',
      jenisIzin: 'Cuti',
      alasan: 'Acara keluarga.',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 10)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 8)),
      status: 'APPROVED',
      bukti: BuktiKind.pdf,
    ),
    LeaveRequestUiModel(
      leaveId: '3',
      jenisIzin: 'Izin',
      alasan: 'Keperluan administrasi.',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 5)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 5)),
      status: 'REJECTED',
      bukti: BuktiKind.none,
    ),
  ];

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));

    setState(() {
      _isLoading = false;
    });
  }

  void _confirmDelete(BuildContext context, LeaveRequestUiModel leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus request ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _requests.removeWhere((e) => e.leaveId == leave.leaveId);
              });
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _onEdit(LeaveRequestUiModel leave) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${leave.jenisIzin} (UI dummy)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Cuti/Izin/Sakit'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null)
          ? Center(child: Text(_errorMessage!))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_requests.isEmpty) const LeaveEmptyState(),
                      ..._requests.map((leave) {
                        return LeaveCard(
                          leave: leave,
                          tanggalMulaiLabel: _formatDateOnly(
                            leave.tanggalMulai,
                          ),
                          tanggalSelesaiLabel: _formatDateOnly(
                            leave.tanggalSelesai,
                          ),
                          buktiLabel: _buktiLabel(leave.bukti),
                          onTap: () => showLeaveDetailBottomSheet(
                            context: context,
                            leave: leave,
                            formatDateOnly: _formatDateOnly,
                          ),
                          onEdit: () => _onEdit(leave),
                          onDelete: () => _confirmDelete(context, leave),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_izin_sakit_cuti',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengajuanScreen()),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  static String _formatDateOnly(DateTime date) {
    final d = date.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _buktiLabel(BuktiKind kind) {
    switch (kind) {
      case BuktiKind.image:
        return 'Gambar';
      case BuktiKind.pdf:
        return 'PDF';
      case BuktiKind.none:
        return 'Tidak ada';
    }
  }
}
