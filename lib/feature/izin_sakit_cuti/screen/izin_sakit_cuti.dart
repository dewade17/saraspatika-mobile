// ignore_for_file: unnecessary_to_list_in_spreads, avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';

class IzinSakitCuti extends StatefulWidget {
  const IzinSakitCuti({super.key});

  @override
  State<IzinSakitCuti> createState() => _IzinSakitCutiState();
}

class _IzinSakitCutiState extends State<IzinSakitCuti> {
  // Simulasi loading & error (UI-only)
  bool _isLoading = false;
  String? _errorMessage;

  // Dummy data
  late List<_LeaveRequestUiModel> _requests = [
    _LeaveRequestUiModel(
      leaveId: '1',
      jenisIzin: 'Sakit',
      alasan: 'Demam tinggi dan butuh istirahat.',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 1)),
      tanggalSelesai: DateTime.now(),
      status: 'PENDING',
      buktiFile: _dummyBase64Png,
    ),
    _LeaveRequestUiModel(
      leaveId: '2',
      jenisIzin: 'Cuti',
      alasan: 'Acara keluarga.',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 10)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 8)),
      status: 'APPROVED',
      buktiFile: _dummyBase64Pdf,
    ),
    _LeaveRequestUiModel(
      leaveId: '3',
      jenisIzin: 'Izin',
      alasan: 'Keperluan administrasi.',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 5)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 5)),
      status: 'REJECTED',
      buktiFile: '',
    ),
  ];

  Future<void> _refreshData() async {
    // UI-only refresh palsu
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));

    setState(() {
      _isLoading = false;
      // optional: kalau mau tes empty state, uncomment:
      // _requests = [];
    });
  }

  void _confirmDelete(BuildContext context, _LeaveRequestUiModel leave) {
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
              // UI-only: hapus dari dummy list
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

  void _onAdd() {
    // UI-only: placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tambah Pengajuan (UI dummy)')),
    );
  }

  void _onEdit(_LeaveRequestUiModel leave) {
    // UI-only: placeholder
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
                      if (_requests.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 200),
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: Opacity(
                                  opacity: 0.5,
                                  child: Image.asset(
                                    'assets/images/Empty-data.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const Text(
                                'Saat Ini Kamu Tidak Memiliki Pengajuan.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ..._requests.map((leave) {
                        final isPending =
                            leave.status == null || leave.status == 'PENDING';

                        return InkWell(
                          onTap: () => _showDetailBottomSheet(context, leave),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.description,
                                        color: Colors.blueAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          leave.jenisIzin.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      if (isPending)
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _onEdit(leave);
                                            } else if (value == 'delete') {
                                              _confirmDelete(context, leave);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.edit,
                                                  color: Colors.blueAccent,
                                                ),
                                                title: Text('Edit'),
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.delete,
                                                  color: Colors.redAccent,
                                                ),
                                                title: Text('Hapus'),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Mulai: ${_formatDateOnly(leave.tanggalMulai)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Berakhir: ${_formatDateOnly(leave.tanggalSelesai)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          (leave.status ?? 'PENDING')
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: _statusColor(
                                          leave.status,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _statusColor(String? status) {
    final s = (status ?? 'PENDING').toUpperCase();
    if (s == 'PENDING') return Colors.orange;
    if (s == 'APPROVED') return Colors.green;
    if (s == 'REJECTED') return Colors.redAccent;
    return Colors.blueGrey;
  }

  static String _formatDateOnly(DateTime date) {
    final d = date.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  void _showDetailBottomSheet(
    BuildContext context,
    _LeaveRequestUiModel leave,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final bukti = leave.buktiFile;
            final isBase64Image = bukti.startsWith('data:image');
            Uint8List? imageBytes;

            if (isBase64Image) {
              try {
                final cleaned = bukti.split(',').last;
                imageBytes = base64Decode(cleaned);
              } catch (_) {
                imageBytes = null;
              }
            }

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
                    children: const [
                      Icon(Icons.description, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Detail Izin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _detailRow(
                    icon: Icons.assignment,
                    label: 'Jenis Izin',
                    value: leave.jenisIzin,
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    icon: Icons.notes,
                    label: 'Keterangan',
                    value: leave.alasan,
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    icon: Icons.date_range,
                    label: 'Tanggal Mulai',
                    value: _formatDateOnly(leave.tanggalMulai),
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    icon: Icons.event_available,
                    label: 'Tanggal Berakhir',
                    value: _formatDateOnly(leave.tanggalSelesai),
                  ),
                  const SizedBox(height: 8),

                  _detailRow(
                    icon: Icons.verified_user,
                    label: 'Status',
                    value: leave.status ?? 'Pending',
                  ),

                  const Divider(height: 32),
                  const Text(
                    'Bukti Pengajuan:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (bukti.isNotEmpty)
                    if (bukti.startsWith('data:image') && imageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Text('Gagal memuat gambar'),
                        ),
                      )
                    else if (bukti.startsWith('data:application/pdf'))
                      Card(
                        color: Colors.red[50],
                        child: ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: const Text('Bukti PDF'),
                          subtitle: const Text('Klik untuk melihat (UI dummy)'),
                          onTap: () {
                            // UI-only: placeholder
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Open PDF (UI dummy)'),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Text('Format bukti tidak dikenali')
                  else
                    const Text('Tidak ada bukti yang diunggah'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.indigo),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =====================
// UI Model (Dummy)
// =====================
class _LeaveRequestUiModel {
  final String leaveId;
  final String jenisIzin;
  final String alasan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String? status; // PENDING/APPROVED/REJECTED
  final String buktiFile; // base64 string (image/pdf) atau kosong

  const _LeaveRequestUiModel({
    required this.leaveId,
    required this.jenisIzin,
    required this.alasan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    required this.buktiFile,
  });
}

// =====================
// Dummy base64 content
// =====================

// 1x1 px transparent PNG
const String _dummyBase64Png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2nWZ8AAAAASUVORK5CYII=';

// Minimal dummy PDF header (bukan PDF valid untuk dibuka, tapi cukup untuk UI preview card)
const String _dummyBase64Pdf = 'data:application/pdf;base64,JVBERi0xLjQK';
