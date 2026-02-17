// ignore_for_file: unused_import, use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';
import 'package:saraspatika/core/utils/image_compress_utils.dart';
import 'package:saraspatika/feature/agenda/data/dto/agenda.dart';
import 'package:saraspatika/feature/agenda/data/provider/agenda_provider.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';

class FormAgendaScreen extends StatefulWidget {
  const FormAgendaScreen({super.key, this.agenda});

  final Agenda? agenda;

  @override
  State<FormAgendaScreen> createState() => _FormAgendaScreenState();
}

class _FormAgendaScreenState extends State<FormAgendaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _deskripsiController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _jamMulaiController = TextEditingController();
  final _jamSelesaiController = TextEditingController();

  DateTime? _tanggal;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  AppPickedFile? _pickedFile;

  bool get _isEditMode => widget.agenda != null;

  @override
  void initState() {
    super.initState();
    _initializeFormForEdit();
  }

  void _initializeFormForEdit() {
    final agenda = widget.agenda;
    if (agenda == null) return;

    _deskripsiController.text = agenda.deskripsi;
    _tanggal = agenda.tanggal;
    _jamMulai = TimeOfDay.fromDateTime(agenda.jamMulai);
    _jamSelesai = TimeOfDay.fromDateTime(agenda.jamSelesai);

    _tanggalController.text = DateFormat('yyyy-MM-dd').format(_tanggal!);
    _jamMulaiController.text = DateFormat('HH:mm').format(agenda.jamMulai);
    _jamSelesaiController.text = DateFormat('HH:mm').format(agenda.jamSelesai);
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _tanggalController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
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
            cameraCompressOptions: const ImageCompressOptions(
              targetBytes: 2 * 1024 * 1024,
            ),
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
        final file = picked.first;
        final bytes = await file.file.length();
        const maxSizeInBytes = 2 * 1024 * 1024;

        if (bytes > maxSizeInBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ukuran file melebihi 2MB. Silakan pilih file lain.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _pickedFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 20),
              titleLarge: TextStyle(fontSize: 16),
              bodyLarge: TextStyle(fontSize: 14),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    final formatter = DateFormat('yyyy-MM-dd');
    setState(() {
      _tanggal = picked;
      _tanggalController.text = formatter.format(picked);
    });
  }

  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null || !mounted) return;

    final normalized =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      if (isStart) {
        _jamMulai = picked;
        _jamMulaiController.text = normalized;
      } else {
        _jamSelesai = picked;
        _jamSelesaiController.text = normalized;
      }
    });
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final shouldRequireProof = !_isEditMode;

    if (!isValid ||
        _tanggal == null ||
        _jamMulai == null ||
        _jamSelesai == null ||
        (shouldRequireProof && _pickedFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field dan pilih bukti.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _jamMulai!.hour,
      _jamMulai!.minute,
    );
    final endDateTime = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _jamSelesai!.hour,
      _jamSelesai!.minute,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai harus lebih besar dari jam mulai.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<AgendaProvider>();

    try {
      if (_isEditMode) {
        await provider.updateAgenda(
          widget.agenda!.idAgenda,
          deskripsi: _deskripsiController.text,
          tanggal: _tanggalController.text,
          jamMulai: _jamMulaiController.text,
          jamSelesai: _jamSelesaiController.text,
          buktiPendukung: _pickedFile,
        );
      } else {
        await provider.createAgenda(
          deskripsi: _deskripsiController.text,
          tanggal: _tanggalController.text,
          jamMulai: _jamMulaiController.text,
          jamSelesai: _jamSelesaiController.text,
          buktiPendukung: _pickedFile,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Agenda berhasil diperbarui.'
                : 'Agenda berhasil disimpan.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan agenda.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AgendaProvider, bool>(
      (provider) => provider.isLoading,
    );
    final user = context.watch<AuthProvider>().me;
    final String labelSuffix = user?.role.toUpperCase() == 'GURU'
        ? 'Mengajar'
        : 'Kerja';

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryColor),
      body: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: AppColors.primaryColor,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  Transform.translate(
                    offset: const Offset(0, -90),
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            _isEditMode
                                ? 'Edit Agenda $labelSuffix'
                                : 'Form Agenda $labelSuffix',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  controller: _deskripsiController,
                                  label: 'Deskripsi $labelSuffix',
                                  alignLabelWithHint: true,
                                  leadingIcon: Icons.work,
                                  minLines: 3,
                                  maxLines: 3,
                                  textInputAction: TextInputAction.newline,
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                      ? 'Deskripsi tidak boleh kosong'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                AppTextField(
                                  controller: _tanggalController,
                                  label: 'Tanggal',
                                  leadingIcon: Icons.date_range,
                                  readOnly: true,
                                  onTap: _selectDate,
                                ),
                                const SizedBox(height: 20),
                                AppTextField(
                                  controller: _jamMulaiController,
                                  label: 'Jam Mulai',
                                  leadingIcon: Icons.access_time,
                                  readOnly: true,
                                  onTap: () => _selectTime(isStart: true),
                                ),
                                const SizedBox(height: 20),
                                AppTextField(
                                  controller: _jamSelesaiController,
                                  label: 'Jam Selesai',
                                  leadingIcon: Icons.access_time,
                                  readOnly: true,
                                  onTap: () => _selectTime(isStart: false),
                                ),
                                const SizedBox(height: 20),
                                AppButton(
                                  onPressed: isLoading ? null : _pickBukti,
                                  variant: AppButtonVariant.outline,
                                  fullWidth: true,
                                  size: AppButtonSize.lg,
                                  leading: const Icon(Icons.upload_file),
                                  text: _pickedFile != null
                                      ? 'Ubah Bukti'
                                      : 'Upload Bukti Foto/File',
                                  borderRadius: 12,
                                ),
                                if (_isEditMode &&
                                    _pickedFile == null &&
                                    widget.agenda?.buktiPendukungUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _buildExistingBuktiPreview(),
                                  ),
                                if (_pickedFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _buildFilePreview(),
                                  ),
                                if (_isEditMode &&
                                    _pickedFile == null &&
                                    widget.agenda?.buktiPendukungUrl != null)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Bukti lama tetap digunakan jika Anda tidak memilih file baru.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 32),
                                AppButton(
                                  onPressed: isLoading ? null : _submitForm,
                                  variant: AppButtonVariant.primary,
                                  fullWidth: true,
                                  size: AppButtonSize.lg,
                                  leading: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  text: isLoading
                                      ? 'Menyimpan...'
                                      : (_isEditMode
                                            ? 'Perbarui Agenda'
                                            : 'Simpan Agenda'),
                                  borderRadius: 12,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingBuktiPreview() {
    final url = widget.agenda!.buktiPendukungUrl!;
    final kind = agendaBuktiKindFromUrl(url);

    if (kind == AgendaBuktiKind.image) {
      return Card(
        margin: EdgeInsets.zero,
        color: Colors.blue[50],
        child: ListTile(
          leading: const Icon(Icons.image, color: Colors.blue),
          title: const Text('Bukti Gambar (Lama)'),
          subtitle: const Text('Klik untuk melihat gambar'),
          onTap: () => _launchURL(url),
        ),
      );
    } else if (kind == AgendaBuktiKind.pdf) {
      return Card(
        margin: EdgeInsets.zero,
        color: Colors.red[50],
        child: ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
          title: const Text('Bukti PDF (Lama)'),
          subtitle: const Text('Klik untuk melihat'),
          onTap: () => _launchURL(url),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilePreview() {
    final fileName = _pickedFile!.path.split('/').last;
    final isImage = [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
    ].any((ext) => fileName.toLowerCase().endsWith(ext));

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _pickedFile!.file,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            fileName.toLowerCase().endsWith('.pdf')
                ? Icons.picture_as_pdf
                : Icons.insert_drive_file,
            color: fileName.toLowerCase().endsWith('.pdf')
                ? Colors.red
                : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _pickedFile = null),
          ),
        ],
      ),
    );
  }
}
