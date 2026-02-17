import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';

class RequestResetWajahScreen extends StatefulWidget {
  const RequestResetWajahScreen({super.key, this.onSubmit});

  final Future<String?> Function(String alasan)? onSubmit;

  @override
  State<RequestResetWajahScreen> createState() =>
      _RequestResetWajahScreenState();
}

class _RequestResetWajahScreenState extends State<RequestResetWajahScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? errorMessage;
    if (widget.onSubmit != null) {
      try {
        errorMessage = await widget.onSubmit!(_alasanController.text.trim());
      } catch (_) {
        errorMessage = 'Pengajuan gagal dikirim.';
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (widget.onSubmit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UI saja (belum terhubung ke API/Provider)'),
        ),
      );
      return;
    }

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryColor),
      body: Stack(
        children: [
          Container(
            height: 260,
            width: double.infinity,
            color: AppColors.primaryColor,
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    'lib/assets/images/Resubmission.png',
                    width: 200,
                    height: 200,
                  ),
                  const Text(
                    "Form Pengajuan Ulang Wajah",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 210),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          offset: Offset(0, 6),
                          color: Color(0x14000000),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _alasanController,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              labelText: 'Keterangan Pengajuan Ulang',
                              alignLabelWithHint: true,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Icon(Icons.edit_note),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 32),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    "Kirim Pengajuan",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.backgroundColor,
                                    ),
                                  ),
                                ),
                        ],
                      ),
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
}
