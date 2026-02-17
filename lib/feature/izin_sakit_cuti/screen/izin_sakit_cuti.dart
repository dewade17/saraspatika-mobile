import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/dto/pengajuan_absensi.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/provider/pengajuan_absensi_provider.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/screen/form_tambah_pengajuan/pengajuan_screen.dart';
import 'widget/leave_card.dart';
import 'widget/leave_detail_sheet.dart';
import 'widget/leave_empty_state.dart';

class IzinSakitCuti extends StatefulWidget {
  const IzinSakitCuti({super.key});

  @override
  State<IzinSakitCuti> createState() => _IzinSakitCutiState();
}

class _IzinSakitCutiState extends State<IzinSakitCuti> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(showError: false);
    });
  }

  Future<void> _refreshData({required bool showError}) async {
    final provider = context.read<PengajuanAbsensiProvider>();

    setState(() => _errorMessage = null);

    try {
      await provider.fetchMyPengajuan();
    } catch (_) {
      final message = provider.errorMessage ?? 'Gagal memuat data pengajuan.';
      if (!mounted) return;
      setState(() => _errorMessage = message);

      if (showError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _confirmDelete(PengajuanData leave) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus request ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final provider = context.read<PengajuanAbsensiProvider>();

    try {
      await provider.deletePengajuan(leave.idPengajuan);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dihapus.')),
      );
    } catch (_) {
      if (!mounted) return;
      final message = provider.errorMessage ?? 'Gagal menghapus pengajuan.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _onEdit(PengajuanData leave) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PengajuanScreen(existingData: leave)),
    );

    if (updated == true && mounted) {
      await _refreshData(showError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PengajuanAbsensiProvider>(
      builder: (context, provider, _) {
        final requests = provider.items;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            foregroundColor: AppColors.backgroundColor,
            title: const Text(
              'Izin, Cuti & Sakit',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.primaryColor,
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_errorMessage != null)
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: () => _refreshData(showError: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (requests.isEmpty) const LeaveEmptyState(),
                          ...requests.map((leave) {
                            return LeaveCard(
                              leave: leave,
                              tanggalMulaiLabel: _formatDateOnly(
                                leave.tanggalMulai,
                              ),
                              tanggalSelesaiLabel: _formatDateOnly(
                                leave.tanggalSelesai,
                              ),
                              onTap: () => showLeaveDetailBottomSheet(
                                context: context,
                                leave: leave,
                                formatDateOnly: _formatDateOnly,
                              ),
                              onEdit: () async => _onEdit(leave),
                              onDelete: () => _confirmDelete(leave),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_izin_sakit_cuti',
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const PengajuanScreen()),
              );

              if (created == true && mounted) {
                await _refreshData(showError: true);
              }
            },
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  static String _formatDateOnly(DateTime date) {
    final d = date.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
