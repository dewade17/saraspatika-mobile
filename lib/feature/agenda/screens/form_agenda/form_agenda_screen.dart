// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';

class FormAgendaScreen extends StatefulWidget {
  const FormAgendaScreen({super.key});

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

  File? galleryFile;
  final ImagePicker picker = ImagePicker();

  @override
  void dispose() {
    _deskripsiController.dispose();
    _tanggalController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    super.dispose();
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                _getImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                _getImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final bytes = await file.length();
    const maxSizeInBytes = 1 * 1024 * 1024; // 1MB

    if (bytes > maxSizeInBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran file melebihi 1MB. Silakan pilih file lain.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      galleryFile = file;
    });
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

    if (picked == null) return;
    if (!mounted) return;

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

    if (picked == null) return;
    if (!mounted) return;

    setState(() {
      if (isStart) {
        _jamMulai = picked;
        _jamMulaiController.text = picked.format(context);
      } else {
        _jamSelesai = picked;
        _jamSelesaiController.text = picked.format(context);
      }
    });
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid ||
        _tanggal == null ||
        _jamMulai == null ||
        _jamSelesai == null ||
        galleryFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field dan pilih foto.'),
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

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai tidak boleh lebih awal dari jam mulai.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // UI only: tidak kirim ke backend
    print('UI Only Submit:');
    print('Deskripsi: ${_deskripsiController.text}');
    print('Tanggal: ${_tanggalController.text}');
    print('Mulai: ${_jamMulaiController.text}');
    print('Selesai: ${_jamSelesaiController.text}');
    print('Foto: ${galleryFile!.path}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Validasi sukses (UI only). Data siap disimpan.'),
      ),
    );

    // Kalau mau auto close setelah submit UI-only:
    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 120),

                  // Title + Form dijadikan satu block dan dipindah naik
                  // agar terlihat berada di area header, tapi tetap ikut scroll.
                  Transform.translate(
                    offset: const Offset(0, -90),
                    child: Column(
                      children: [
                        const Center(
                          child: Text(
                            "Form Agenda Mengajar",
                            style: TextStyle(
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
                                  label: 'Deskripsi Mengajar',
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
                                  onPressed: () => _showPicker(context),
                                  variant: AppButtonVariant.outline,
                                  fullWidth: true,
                                  size: AppButtonSize.lg,
                                  leading: const Icon(Icons.upload_file),
                                  text: 'Upload Bukti Foto',
                                  borderRadius: 12,
                                ),
                                if (galleryFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        galleryFile!,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 32),
                                AppButton(
                                  onPressed: _submitForm,
                                  variant: AppButtonVariant.primary,
                                  fullWidth: true,
                                  size: AppButtonSize.lg,
                                  leading: const Icon(Icons.save),
                                  text: 'Simpan Agenda',
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

                  // Space bawah biar enak scroll sampai akhir
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  