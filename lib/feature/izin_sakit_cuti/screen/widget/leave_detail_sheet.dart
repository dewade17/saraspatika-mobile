import 'package:flutter/material.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/dto/pengajuan_absensi.dart';

void showLeaveDetailBottomSheet({
  required BuildContext context,
  required PengajuanData leave,
  required String Function(DateTime) formatDateOnly,
}) {
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
                  label: leave.jenisPengajuan,
                  value: leave.jenisPengajuan,
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
                  value: formatDateOnly(leave.tanggalMulai),
                ),
                const SizedBox(height: 8),
                _detailRow(
                  icon: Icons.event_available,
                  label: 'Tanggal Berakhir',
                  value: formatDateOnly(leave.tanggalSelesai),
                ),
                const SizedBox(height: 8),
                _detailRow(
                  icon: Icons.verified_user,
                  label: 'Status',
                  value: leave.status,
                ),
                const Divider(height: 32),
                const Text(
                  'Bukti Pengajuan:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                  const SizedBox(height: 12),
                  if (leave.buktiKind == BuktiKind.image)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                        color: Colors.grey[50],
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_outlined, size: 40),
                            SizedBox(height: 8),
                            Text('Preview Gambar (UI dummy)'),
                          ],
                        ),
                      ),
                    )
                  else if (leave.buktiKind == BuktiKind.pdf)
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Open PDF (UI dummy)')),
                          );
                        },
                      ),
                    )
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
