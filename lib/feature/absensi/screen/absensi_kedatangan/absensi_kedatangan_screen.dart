import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_checkin.dart';
import 'package:saraspatika/feature/absensi/data/dto/jadwal_shift.dart';
import 'package:saraspatika/feature/absensi/data/provider/absensi_provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/jadwal_shift_provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/lokasi_provider.dart';
import 'package:saraspatika/feature/absensi/screen/face_detection/face_detection_screen.dart';
import 'package:quickalert/quickalert.dart';

class AbsensiKedatanganScreen extends StatefulWidget {
  const AbsensiKedatanganScreen({super.key});

  @override
  State<AbsensiKedatanganScreen> createState() =>
      _AbsensiKedatanganScreenState();
}

class _AbsensiKedatanganScreenState extends State<AbsensiKedatanganScreen> {
  final MapController _mapController = MapController();

  LatLng _markerPosition = const LatLng(-8.670458, 115.212629);

  double _zoom = 15.7;

  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initLocation();
      if (!mounted) return;

      final jadwalProvider = context.read<JadwalShiftProvider>();
      final absensiProvider = context.read<AbsensiProvider>();

      try {
        // Jalankan fetch jadwal dan status absensi secara paralel
        await Future.wait([
          jadwalProvider.fetchTodayShift(),
          absensiProvider.fetchStatus(), // Mengambil data status terbaru
        ]);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = context.watch<AbsensiProvider>();
    final jadwalProvider = context.watch<JadwalShiftProvider>();
    final lokasiProvider = context.watch<LokasiProvider>();
    final selectedLocation = lokasiProvider.selectedLocation;

    // --- LOGIKA STATUS ABSENSI ---
    final statusItem = absensiProvider.status?.item;
    final bool isAlreadyCheckedIn = statusItem?.waktuMasuk != null;

    // Tentukan teks status untuk Info Card
    String displayStatus = 'Belum\nabsen';
    Color statusColor = const Color(0xFFE85A5A); // Merah untuk belum absen

    if (isAlreadyCheckedIn) {
      displayStatus = statusItem?.statusMasuk ?? "TEPAT";

      // Cek apakah status mengandung kata "TERLAMBAT"
      if (displayStatus.toUpperCase().contains('TERLAMBAT')) {
        statusColor = Colors.redAccent; // Warna peringatan untuk terlambat
      } else {
        statusColor = const Color(0xFF57B87B); // Hijau untuk TEPAT
      }
    }
    // -----------------------------

    // --- LOGIKA PENGECEKAN RADIUS ---
    double distanceInMeters = 0.0;
    bool isWithinRadius = false;

    if (selectedLocation != null) {
      // Menghitung jarak antara koordinat user dan koordinat kantor
      distanceInMeters = Geolocator.distanceBetween(
        _markerPosition.latitude,
        _markerPosition.longitude,
        selectedLocation.latitude,
        selectedLocation.longitude,
      );

      // Cek apakah jarak lebih kecil atau sama dengan radius (misal 70m)
      isWithinRadius = distanceInMeters <= selectedLocation.radius;
    }
    // --------------------------------

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF57B87B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Absensi Kedatangan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _markerPosition,
              initialZoom: _zoom,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: (event) {
                final newZoom = event.camera.zoom;
                if (newZoom != _zoom) {
                  setState(() => _zoom = newZoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'id.mycompany.saraspatika',
              ),
              if (selectedLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        selectedLocation.latitude,
                        selectedLocation.longitude,
                      ),
                      radius: selectedLocation.radius
                          .toDouble(), // Radius 70 meter
                      useRadiusInMeter:
                          true, // WAJIB true agar radius dihitung dalam meter, bukan pixel
                      color: const Color(
                        0xFF57B87B,
                      ).withOpacity(0.2), // Warna isi transparan
                      borderColor: const Color(
                        0xFF57B87B,
                      ), // Warna garis pinggir
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _markerPosition,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E6DFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _InfoCard(
              tanggal: DateFormat(
                'EEEE, dd MMMM yyyy',
                'id_ID',
              ).format(DateTime.now()),
              sekolah:
                  lokasiProvider.selectedLocation?.namaLokasi ??
                  'Mencari lokasi...',
              status: displayStatus,
              statusColor: statusColor,
              isLoadingJadwal: jadwalProvider.isLoading,
              jadwalShift: jadwalProvider.todayShift,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 88,
            child: _ZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
          ),
          Positioned(
            left: 12,
            bottom: 100,
            child: _CircleMapButton(
              icon: _isLocating ? Icons.hourglass_top : Icons.my_location,
              onTap: _isLocating ? () {} : _recenterWithPermission,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: AppButton(
              text: isAlreadyCheckedIn
                  ? 'Sudah Absen Masuk'
                  : (selectedLocation == null
                        ? 'Mencari Lokasi...'
                        : (isWithinRadius
                              ? 'Verifikasi Wajah'
                              : 'Di Luar Radius (${distanceInMeters.toStringAsFixed(0)}m)')),
              fullWidth: true,
              isLoading: absensiProvider.isLoading,
              manageInternalLoading: false,
              backgroundColor: (isWithinRadius && !isAlreadyCheckedIn)
                  ? const Color(0xFF57B87B)
                  : Colors.grey.shade400,
              onPressedAsync: (isWithinRadius && !isAlreadyCheckedIn)
                  ? _handleFaceVerification
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFaceVerification() async {
    // 1. Ambil foto dari Kamera
    final File? photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const FaceDetectionScreen()),
    );

    if (!mounted || photo == null) return;

    final lokasiProvider = context.read<LokasiProvider>();
    final absensiProvider = context.read<AbsensiProvider>();
    final selectedLocation = lokasiProvider.selectedLocation;

    if (selectedLocation == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Lokasi Tidak Ditemukan',
        text: 'Lokasi absensi belum dipilih atau tidak terdeteksi.',
      );
      return;
    }

    // --- Perubahan: Gunakan QuickAlert untuk Feedback ---

    // 2. Tampilkan Loading Alert
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Memproses...',
      text: 'Mengirim data absensi dan memverifikasi wajah.',
      barrierDismissible: false,
    );

    try {
      // 3. Eksekusi Check-In
      await absensiProvider.checkIn(
        request: CheckInRequest(
          userId: '', // ID akan di-resolve otomatis oleh provider
          locationId: selectedLocation.idLokasi,
          lat: _markerPosition.latitude,
          lng: _markerPosition.longitude,
          capturedAt: DateTime.now().toIso8601String(),
        ),
        imageFile: photo,
      );

      // Ambil jam masuk dari status terbaru setelah berhasil check-in
      final statusItem = absensiProvider.status?.item;
      String jamMasuk = statusItem?.waktuMasuk != null
          ? DateFormat('HH:mm').format(statusItem!.waktuMasuk!.toLocal())
          : DateFormat('HH:mm').format(DateTime.now());

      if (!mounted) return;

      // Tutup loading alert sebelum menampilkan sukses
      Navigator.of(context, rootNavigator: true).pop();

      // 4. Tampilkan QuickAlert Sukses
      await QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Berhasil!',
        text: 'Anda berhasil melakukan check-in pada pukul $jamMasuk.',
        confirmBtnText: 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); // Tutup dialog QuickAlert
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      if (!mounted) return;

      // Tutup loading alert sebelum menampilkan error
      Navigator.of(context, rootNavigator: true).pop();

      // 5. Tampilkan QuickAlert Error
      final msg = absensiProvider.errorMessage ?? 'Gagal memproses absensi: $e';
      await QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Terjadi Kesalahan',
        text: msg,
        confirmBtnText: 'Coba Lagi',
      );
    }
  }

  Future<void> _initLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await _determinePosition();

      // --- PENGECEKAN FAKE GPS ---
      // Di Android, geolocator memiliki flag isMocked
      if (pos.isMocked) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lokasi Palsu Terdeteksi'),
            content: const Text(
              'Harap matikan aplikasi Fake GPS atau Mock Location untuk melakukan absensi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return; // Hentikan proses jika terdeteksi Fake GPS
      }
      // ---------------------------

      final latLng = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() => _markerPosition = latLng);

      _mapController.move(latLng, _zoom);

      final lokasiProvider = context.read<LokasiProvider>();
      await lokasiProvider.fetchNearestLocations(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil lokasi: $e')));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _recenterWithPermission() async {
    await _initLocation();
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationServicesDialog();
      throw 'Location services (GPS) tidak aktif';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin lokasi ditolak';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showOpenSettingsDialog();
      throw 'Izin lokasi ditolak permanen. Aktifkan lewat Settings.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _showOpenSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Izin lokasi dibutuhkan'),
          content: const Text(
            'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openAppSettings();
              },
              child: const Text('Buka Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLocationServicesDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('GPS tidak aktif'),
          content: const Text(
            'Aktifkan Location Services (GPS) agar aplikasi bisa mengambil lokasi untuk absensi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openLocationSettings();
              },
              child: const Text('Buka Pengaturan Lokasi'),
            ),
          ],
        );
      },
    );
  }

  void _zoomIn() {
    final next = (_zoom + 1).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, next);
  }

  void _zoomOut() {
    final next = (_zoom - 1).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, next);
  }
}

class _InfoCard extends StatelessWidget {
  final String tanggal;
  final String sekolah;
  final String status;
  final Color statusColor;
  final bool isLoadingJadwal;
  final JadwalShift? jadwalShift;

  const _InfoCard({
    required this.tanggal,
    required this.sekolah,
    required this.statusColor,
    required this.status,
    required this.isLoadingJadwal,
    required this.jadwalShift,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE49A),
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tanggal,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sekolah,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: statusColor,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: isLoadingJadwal
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      jadwalShift == null
                          ? 'Jadwal shift hari ini tidak tersedia.'
                          : 'Shift Mengajar: ${jadwalShift?.jamMulaiKerja != null ? DateFormat('HH:mm').format(jadwalShift!.jamMulaiKerja!) : "--:--"} - ${jadwalShift?.jamSelesaiKerja != null ? DateFormat('HH:mm').format(jadwalShift!.jamSelesaiKerja!) : "--:--"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: Color(0xFF333333),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({required this.onZoomIn, required this.onZoomOut});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add, onTap: onZoomIn, topRounded: true),
          const Divider(height: 1, thickness: 1),
          _ZoomButton(
            icon: Icons.remove,
            onTap: onZoomOut,
            bottomRounded: true,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool topRounded;
  final bool bottomRounded;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    this.topRounded = false,
    this.bottomRounded = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topRounded ? 10 : 0),
        topRight: Radius.circular(topRounded ? 10 : 0),
        bottomLeft: Radius.circular(bottomRounded ? 10 : 0),
        bottomRight: Radius.circular(bottomRounded ? 10 : 0),
      ),
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, size: 22, color: const Color(0xFF333333)),
      ),
    );
  }
}

class _CircleMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleMapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(icon, size: 22)),
        ),
      ),
    );
  }
}
