import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';

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

  final String _tanggal = 'Minggu, 13 Juli 2025';
  final String _sekolah = 'SD SARASWATI 4 DENPASAR';
  final String _status = 'Belum\nabsen';

  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                subdomains: const [
                  'a',
                  'b',
                  'c',
                  'd',
                ], // Dibutuhkan untuk CartoDB
                userAgentPackageName: 'id.mycompany.saraspatika',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _markerPosition,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF1E6DFF),
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
              tanggal: _tanggal,
              sekolah: _sekolah,
              status: _status,
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
            left: 12, // Batas kiri
            right: 12, // TAMBAHKAN INI agar lebar terdefinisi
            bottom:
                24, // Saya sesuaikan jarak bawahnya agar tidak menumpuk dengan tombol lokasi
            child: AppButton(
              text: 'Verifikasi Wajah',
              fullWidth: true,
              manageInternalLoading: false,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await _determinePosition();
      final latLng = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() => _markerPosition = latLng);

      _mapController.move(latLng, _zoom);
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

  const _InfoCard({
    required this.tanggal,
    required this.sekolah,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE49A),
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: Color(0xFFE85A5A),
                    height: 1.05,
                  ),
                ),
              ],
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
