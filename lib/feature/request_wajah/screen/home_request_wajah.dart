import 'package:flutter/material.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/request_wajah/screen/form_request_wajah/request_reset_wajah_screen.dart';

class FaceReenrollmentItem {
  final String alasan;
  final String status;
  final String? catatan;
  final DateTime createdAt;

  FaceReenrollmentItem({
    required this.alasan,
    required this.status,
    this.catatan,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class HomeRequestWajah extends StatefulWidget {
  const HomeRequestWajah({super.key});

  @override
  State<HomeRequestWajah> createState() => _HomeRequestWajahState();
}

class _HomeRequestWajahState extends State<HomeRequestWajah> {
  bool _faceRegistered = false;
  bool _loading = true;
  List<FaceReenrollmentItem> _recentRequests = [];

  @override
  void initState() {
    super.initState();
    _loadUiOnlyData();
  }

  Future<void> _loadUiOnlyData() async {
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    setState(() {
      _loading = false;

      // Default UI-only sample (boleh dihapus kalau mau kosong)
      _faceRegistered = true;
      _recentRequests = [
        FaceReenrollmentItem(
          alasan: 'Kamera depan buram, wajah tidak terbaca',
          status: 'MENUNGGU',
        ),
        FaceReenrollmentItem(
          alasan: 'Perubahan bentuk wajah (pakai kacamata)',
          status: 'DITOLAK',
          catatan: 'Mohon gunakan pencahayaan yang cukup saat verifikasi.',
        ),
        FaceReenrollmentItem(
          alasan: 'Data wajah lama tidak sesuai',
          status: 'SETUJU',
          catatan: 'Silakan lakukan perekaman ulang.',
        ),
      ];
    });
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Refresh UI saja')));
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'SETUJU':
        return Colors.green.shade100;
      case 'DITOLAK':
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'SETUJU':
        return Colors.green;
      case 'DITOLAK':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'SETUJU') return 'SETUJU';
    if (s == 'DITOLAK') return 'DITOLAK';
    return 'MENUNGGU';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.face_retouching_natural, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Identifikasi Wajah',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      if (_faceRegistered != true) ...[
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/Face.png',
                                width: 200,
                                height: 200,
                              ),
                              const Text(
                                'Silakan Lakukan Registrasi Wajah \n  Terlebih Dahulu.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _faceRegistered = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Simulasi: Face ID terdaftar (UI saja)',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Daftar Face ID'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Card(
                          color: Colors.orange[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.verified_user,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Registrasi Wajah Berhasil",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Anda sudah melakukan registrasi wajah.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Ajukan ulang jika data wajah sudah tidak sesuai.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_recentRequests.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.history_edu,
                                      color: Colors.indigo,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Riwayat Pengajuan Wajah',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recentRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = _recentRequests[index];

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '📝 Alasan:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(request.alasan),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '📌 Status:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _statusBg(request.status),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _statusLabel(request.status),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _statusFg(
                                                  request.status,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (request.catatan != null &&
                                              request.catatan!
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            const Text(
                                              '📄 Catatan:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(request.catatan!),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text(
                                "Belum ada pengajuan ulang wajah",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: (_faceRegistered == true)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestResetWajahScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add_circle),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
