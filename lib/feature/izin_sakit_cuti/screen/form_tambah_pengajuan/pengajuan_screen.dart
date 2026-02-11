import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_date_picker_field.dart';
import 'package:saraspatika/core/shared_widgets/app_drop_down.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

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

  @override
  void dispose() {
    _mulaiDates.dispose();
    _selesaiDates.dispose();
    _buktiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, 1, 1);
    final lastDate = DateTime(now.year + 5, 12, 31);

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
                // HEADER (ikut scroll)
                Container(
                  height: 200,
                  color: AppColors.primaryColor,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 30, left: 70, right: 70),
                    child: Text(
                      "Form Permohonan Cuti/Izin/Sakit",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // FORM CARD (ditarik naik biar overlap header)
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
                            enabled: false,
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
                            enabled: false,
                            allowClear: false,
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
                            enabled: false,
                            allowClear: false,
                          ),

                          const SizedBox(height: 20),

                          const AppTextField(
                            label: 'Alasan',
                            leadingIcon: Icons.comment,
                            maxLines: 3,
                            enabled: false,
                          ),

                          const SizedBox(height: 20),

                          AppFilePickerField(
                            controller: _buktiController,
                            label: 'Bukti',
                            hintText: 'Belum ada file diunggah',
                            leadingIcon: Icons.insert_drive_file_outlined,
                            enabled: false,
                            allowClear: false,
                            allowCamera: true,
                            allowGallery: true,
                            allowFileSystem: true,
                          ),

                          const SizedBox(height: 32),

                          const AppButton(
                            text: 'Unggah Bukti',
                            variant: AppButtonVariant.outline,
                            leading: Icon(Icons.camera_alt_outlined),
                            fullWidth: true,
                            enabled: false,
                          ),

                          const SizedBox(height: 16),

                          const AppButton(
                            text: 'Kirim Permintaan',
                            variant: AppButtonVariant.primary,
                            fullWidth: true,
                            enabled: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ruang bawah biar enak
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
