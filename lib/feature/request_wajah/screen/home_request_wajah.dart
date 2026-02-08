import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/provider/get_face_provider.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';
import 'package:saraspatika/feature/registrasi_wajah/screen/registrasi_wajah.dart';
import 'package:saraspatika/feature/request_wajah/data/dto/request_wajah.dart';
import 'package:saraspatika/feature/request_wajah/data/provider/request_wajah_provider.dart';
import 'package:saraspatika/feature/request_wajah/screen/form_request_wajah/request_reset_wajah_screen.dart';

class HomeRequestWajah extends StatefulWidget {
  const HomeRequestWajah({super.key});

  @override
  State<HomeRequestWajah> createState() => _HomeRequestWajahState();
}

class _HomeRequestWajahState extends State<HomeRequestWajah> {
  bool? _faceRegistered; // null = belum diketahui (loading)
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<String?> _resolveUserId() async {
    final auth = context.read<AuthProvider>();
    final fromAuth = (auth.me?.idUser ?? '').trim();
    if (fromAuth.isNotEmpty) return fromAuth;

    try {
      return (await ApiService().getUserId())?.trim();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _fetchFaceRegistered(String userId) async {
    final getFaceProvider = context.read<GetFaceProvider>();
    try {
      final face = await getFaceProvider.fetchFaceData(userId, maxRetries: 3);
      return face != null && face.items.isNotEmpty;
    } catch (e) {
      // Konsisten dengan AuthWrapper: 404 = belum ada data wajah
      if (e is ApiException && e.statusCode == 404) return false;

      final msg = getFaceProvider.errorMessage ?? 'Gagal mengambil data wajah.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      // Fail-safe: anggap belum terdaftar kalau error non-404 (biar tidak salah kasih akses)
      return false;
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _faceRegistered = null;
    });

    final userId = await _resolveUserId();
    if (!mounted) return;

    if (userId == null || userId.isEmpty) {
      setState(() {
        _faceRegistered = false;
        _initialLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    final hasFace = await _fetchFaceRegistered(userId);
    if (!mounted) return;

    setState(() => _faceRegistered = hasFace);

    if (hasFace) {
      await _loadRequests(showError: true);
    }

    if (!mounted) return;
    setState(() => _initialLoading = false);
  }

  Future<void> _loadRequests({required bool showError}) async {
    final provider = context.read<RequestWajahProvider>();
    try {
      await provider.fetchMyRequests();
    } catch (_) {
      if (!showError || !mounted) return;
      final message = provider.errorMessage ?? 'Gagal memuat data.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _onRefresh() async {
    final userId = await _resolveUserId();
    if (!mounted) return;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak ditemukan. Silakan login ulang.'),
        ),
      );
      return;
    }

    final hasFace = await _fetchFaceRegistered(userId);
    if (!mounted) return;

    setState(() => _faceRegistered = hasFace);

    if (hasFace) {
      await _loadRequests(showError: true);
    }
  }

  Future<void> _openRequestReset() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RequestResetWajahScreen(
          onSubmit: (alasan) async {
            try {
              await context.read<RequestWajahProvider>().createRequest(
                alasan: alasan,
              );
              return null;
            } catch (_) {
              final message =
                  context.read<RequestWajahProvider>().errorMessage ??
                  'Pengajuan gagal dikirim.';
              return message;
            }
          },
        ),
      ),
    );

    if (!mounted) return;
    if (res == true) {
      await _onRefresh();
    }
  }

  String _normStatus(String status) => status.trim().toLowerCase();

  Color _statusBg(String status) {
    switch (_normStatus(status)) {
      case 'setuju':
      case 'disetujui':
      case 'approved':
        return Colors.green.shade100;
      case 'ditolak':
      case 'rejected':
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _statusFg(String status) {
    switch (_normStatus(status)) {
      case 'setuju':
      case 'disetujui':
      case 'approved':
        return Colors.green;
      case 'ditolak':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    final s = _normStatus(status);
    if (s == 'setuju' || s == 'disetujui' || s == 'approved') return 'SETUJU';
    if (s == 'ditolak' || s == 'rejected') return 'DITOLAK';
    return 'MENUNGGU';
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date.toLocal());
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestWajahProvider>();

    final isLoading =
        provider.isLoading || _initialLoading || _faceRegistered == null;
    final hasFace = _faceRegistered == true;

    final List<FaceResetRequest> requests = List<FaceResetRequest>.from(
      provider.requests,
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      if (!hasFace) ...[
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'lib/assets/images/Face.png',
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
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegistrasiWajah(),
                                    ),
                                  );
                                  if (!mounted) return;
                                  await _onRefresh();
                                },
                                child: const Text('Registrasi Wajah'),
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
                        if (requests.isNotEmpty) ...[
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
                                  itemCount: requests.length,
                                  itemBuilder: (context, index) {
                                    final item = requests[index];

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
                                          Text(item.alasan),
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
                                              color: _statusBg(item.status),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _statusLabel(item.status),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _statusFg(item.status),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '🕒 Diajukan: ${_formatDate(item.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          if (item.adminNote != null &&
                                              item.adminNote!.trim().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '📄 Catatan:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(item.adminNote!),
                                                ],
                                              ),
                                            ),
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: (!isLoading && hasFace)
          ? FloatingActionButton(
              heroTag: null,
              onPressed: _openRequestReset,
              child: const Icon(Icons.add_circle),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
