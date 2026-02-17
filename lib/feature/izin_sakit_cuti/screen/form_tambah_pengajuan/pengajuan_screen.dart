// ignore_for_file: use_build_context_synchronously

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_date_picker_field.dart';
import 'package:saraspatika/core/shared_widgets/app_drop_down.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';
import 'package:saraspatika/core/utils/image_compress_utils.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/dto/pengajuan_absensi.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/provider/pengajuan_absensi_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key, this.existingData});

  final PengajuanData? existingData;

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  static const List<String> _jenisIzinList = ['IZIN', 'CUTI', 'SAKIT'];
  String? _selectedJenisIzin;

  final ValueNotifier<List<DateTime>> _mulaiDates =
      ValueNotifier<List<DateTime>>(<DateTime>[]);
  final ValueNotifier<List<DateTime>> _selesaiDates =
      ValueNotifier<List<DateTime>>(<DateTime>[]);

  final AppFilePickerController _buktiController = AppFilePickerController();
  final TextEditingController _alasanController = TextEditingController();

  bool get _isEditing => widget.existingData != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingData;
    if (existing == null) return;

    _selectedJenisIzin = existing.jenisPengajuan.trim().toUpperCase();
    _mulaiDates.value = <DateTime>[existing.tanggalMulai];
    _selesaiDates.value = <DateTime>[existing.tanggalSelesai];
    _alasanController.text = existing.alasan;
  }

  @override
  void dispose() {
    _mulaiDates.dispose();
    _selesaiDates.dispose();
    _buktiController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _pickBukti() async {
    final source = await AppFilePicker.showSourceChooser(
      context,
      allowCamera: true,
      allowGallery: true,
      allowFileSystem: true,
      dialogTitle: 'Pilih Sumber Bukti',
    );

    if (source == null) return;

    List<AppPickedFile> picked = [];

    try {
      switch (source) {
        case AppFileSource.camera:
          picked = await AppFilePicker.pickFromCamera(
            context: context,
            compressCameraImage: true,
            cameraCompressOptions: const ImageCompressOptions(),
          );
          break;
        case AppFileSource.gallery:
          picked = await AppFilePicker.pickFromGallery(
            context: context,
            mode: AppFilePickerMode.imagesOnly,
            allowMultiple: false,
          );
          break;
        case AppFileSource.fileSystem:
          picked = await AppFilePicker.pickFromFileSystem(
            context: context,
            mode: AppFilePickerMode.any,
            fileType: FileType.any,
            allowMultiple: false,
          );
          break;
      }

      if (picked.isNotEmpty) {
        _buktiController.setFiles(picked);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking file: $e');
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _submit(PengajuanAbsensiProvider provider) async {
    final mulai = _mulaiDates.value.isNotEmpty ? _mulaiDates.value.first : null;
    final selesai = _selesaiDates.value.isNotEmpty
        ? _selesaiDates.value.first
        : null;

    if (_selectedJenisIzin == null || _selectedJenisIzin!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis izin wajib dipilih.')),
      );
      return;
    }

    if (mulai == null || selesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal mulai dan selesai wajib diisi.')),
      );
      return;
    }

    if (selesai.isBefore(mulai)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai tidak boleh lebih awal dari mulai.'),
        ),
      );
      return;
    }

    final alasan = _alasanController.text.trim();
    if (alasan.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alasan wajib diisi.')));
      return;
    }

    final bukti = _buktiController.value.isNotEmpty
        ? _buktiController.value.first
        : null;

    try {
      if (_isEditing) {
        await provider.updatePengajuan(
          widget.existingData!.idPengajuan,
          jenisPengajuan: _selectedJenisIzin!,
          tanggalMulai: _formatDate(mulai),
          tanggalSelesai: _formatDate(selesai),
          alasan: alasan,
          fotoBukti: bukti,
          fotoBuktiUrl: bukti == null
              ? widget.existingData!.fotoBuktiUrl
              : null,
        );
      } else {
        await provider.createPengajuan(
          jenisPengajuan: _selectedJenisIzin!,
          tanggalMulai: _formatDate(mulai),
          tanggalSelesai: _formatDate(selesai),
          alasan: alasan,
          fotoBukti: bukti,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Pengajuan berhasil diperbarui.'
                : 'Pengajuan berhasil dikirim.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      final message =
          provider.errorMessage ??
          (_isEditing
              ? 'Gagal memperbarui pengajuan.'
              : 'Gagal mengirim pengajuan.');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, 1, 1);
    final lastDate = DateTime(now.year + 5, 12, 31);

    return Consumer<PengajuanAbsensiProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(backgroundColor: AppColors.primaryColor),
          body: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 200,
                      color: AppColors.primaryColor,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 30, left: 70, right: 70),
                        child: Text(
                          'Form Permohonan Izin, Cuti & Sakit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -70),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              AppDropdownField<String>(
                                items: _jenisIzinList,
                                mode: AppDropdownSelectionMode.single,
                                initialValue: _selectedJenisIzin == null
                                    ? null
                                    : <String>[_selectedJenisIzin!],
                                label: 'Jenis Izin',
                                leadingIcon: Icons.list_alt,
                                enabled: !provider.isLoading,
                                onSingleChanged: (val) {
                                  setState(() => _selectedJenisIzin = val);
                                },
                              ),
                              const SizedBox(height: 20),
                              AppDatePickerField(
                                controller: _mulaiDates,
                                mode: AppDateSelectionMode.single,
                                firstDate: firstDate,
                                lastDate: lastDate,
                                label: 'Mulai',
                                hintText: 'YYYY-MM-DD',
                                leadingIcon: Icons.date_range,
                                enabled: !provider.isLoading,
                                allowClear: true,
                              ),
                              const SizedBox(height: 20),
                              AppDatePickerField(
                                controller: _selesaiDates,
                                mode: AppDateSelectionMode.single,
                                firstDate: firstDate,
                                lastDate: lastDate,
                                label: 'Selesai',
                                hintText: 'YYYY-MM-DD',
                                leadingIcon: Icons.date_range_outlined,
                                enabled: !provider.isLoading,
                                allowClear: true,
                              ),
                              const SizedBox(height: 20),
                              AppTextField(
                                controller: _alasanController,
                                label: 'Alasan',
                                leadingIcon: Icons.comment,
                                maxLines: 3,
                                enabled: !provider.isLoading,
                              ),
                              const SizedBox(height: 20),
                              ValueListenableBuilder(
                                valueListenable: _buktiController,
                                builder: (context, files, _) {
                                  final hasFile = files.isNotEmpty;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppButton(
                                        text: hasFile
                                            ? 'Ubah Bukti'
                                            : (_isEditing
                                                  ? 'Unggah Bukti Baru'
                                                  : 'Unggah Bukti'),
                                        variant: AppButtonVariant.outline,
                                        leading: const Icon(
                                          Icons.camera_alt_outlined,
                                        ),
                                        fullWidth: true,
                                        enabled: !provider.isLoading,
                                        onPressed: _pickBukti,
                                      ),
                                      // Bagian Bukti Sebelumnya (Visual Preview)
                                      if (!hasFile &&
                                          _isEditing &&
                                          (widget.existingData!.fotoBuktiUrl
                                              .trim()
                                              .isNotEmpty)) ...[
                                        const SizedBox(height: 20),
                                        const Text(
                                          'Bukti Sebelumnya:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Gaya Kartu untuk Bukti Gambar
                                        if (widget.existingData!.buktiKind ==
                                            BuktiKind.image)
                                          Card(
                                            margin: EdgeInsets.zero,
                                            color: Colors
                                                .blue[50], // Biru muda untuk Gambar
                                            child: ListTile(
                                              leading: const Icon(
                                                Icons.image,
                                                color: Colors.blue,
                                              ),
                                              title: const Text('Bukti Gambar'),
                                              subtitle: const Text(
                                                'Klik untuk melihat gambar',
                                              ),
                                              onTap: () async {
                                                final uri = Uri.tryParse(
                                                  widget
                                                      .existingData!
                                                      .fotoBuktiUrl,
                                                );
                                                if (uri != null &&
                                                    await canLaunchUrl(uri)) {
                                                  await launchUrl(
                                                    uri,
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                }
                                              },
                                            ),
                                          )
                                        // Gaya Kartu untuk Bukti PDF
                                        else if (widget
                                                .existingData!
                                                .buktiKind ==
                                            BuktiKind.pdf)
                                          Card(
                                            margin: EdgeInsets.zero,
                                            color: Colors
                                                .red[50], // Merah muda untuk PDF
                                            child: ListTile(
                                              leading: const Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.red,
                                              ),
                                              title: const Text('Bukti PDF'),
                                              subtitle: const Text(
                                                'Klik untuk melihat',
                                              ),
                                              onTap: () async {
                                                final uri = Uri.tryParse(
                                                  widget
                                                      .existingData!
                                                      .fotoBuktiUrl,
                                                );
                                                if (uri != null &&
                                                    await canLaunchUrl(uri)) {
                                                  await launchUrl(
                                                    uri,
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                      ],
                                      // Tampilkan nama file jika baru dipilih
                                      if (hasFile) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.insert_drive_file,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  files.first.path
                                                      .split('/')
                                                      .last,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _buktiController.clear(),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              AppButton(
                                text: _isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Kirim Permintaan',
                                variant: AppButtonVariant.primary,
                                fullWidth: true,
                                enabled: !provider.isLoading,
                                isLoading: provider.isLoading,
                                onPressed: () => _submit(provider),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
