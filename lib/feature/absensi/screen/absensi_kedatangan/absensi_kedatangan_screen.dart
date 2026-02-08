import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:saraspatika/core/database/database_helper.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/feature/absensi/data/dto/jadwal_shift.dart';
import 'package:saraspatika/feature/absensi/data/provider/absensi_provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/jadwal_shift_provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/lokasi_provider.dart';
import 'package:saraspatika/feature/absensi/screen/face_detection/face_detection_screen.dart';
import 'package:saraspatika/feature/absensi/data/provider/offline_provider.dart';

class AbsensiKedatanganScreen extends StatefulWidget {
  const AbsensiKedatanganScreen({super.key});

  @override
  State<AbsensiKedatanganScreen> createState() =>
      _AbsensiKedatanganScreenState();
}

class _AbsensiKedatanganScreenState extends State<AbsensiKedatanganScreen> {
  static const LatLng _fallbackCenter = LatLng(-8.670458, 115.212629);

  final MapController _mapController = MapController();
  double _zoom = 15.7;

  AbsensiProvider? _absensiProvider;
  LokasiProvider? _lokasiProvider;

  bool _absensiLoadingDialogVisible = false;
  double? _lastCenteredLat;
  double? _lastCenteredLng;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _absensiProvider = context.read<AbsensiProvider>();
      _lokasiProvider = context.read<LokasiProvider>();

      _absensiProvider?.addListener(_onAbsensiProviderChanged);
      _lokasiProvider?.addListener(_onLokasiProviderChanged);

      await _lokasiProvider?.refreshCurrentLocationAndNearest();
      await _loadCachedLocationsIfNeeded();

      if (!mounted) return;

      final jadwalProvider = context.read<JadwalShiftProvider>();
      try {
        await Future.wait([
          jadwalProvider.fetchTodayShift(),
          _absensiProvider!.fetchStatus(),
        ]);
      } catch (e) {
        await _loadCachedShiftIfNeeded();
        if (!mounted) return;
        if (jadwalProvider.todayShift == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
        }
      }
    });
  }

  Future<void> _loadCachedLocationsIfNeeded() async {
    final lokasiProvider = _lokasiProvider;
    if (lokasiProvider == null) return;

    if (lokasiProvider.selectedLocation != null) return;

    final cachedLocations = await DatabaseHelper.instance.getCachedLocations();
    if (cachedLocations.isEmpty) return;

    lokasiProvider.applyCachedLocations(
      cachedLocations,
      coordinate: lokasiProvider.currentCoordinate,
    );
  }

  Future<void> _loadCachedShiftIfNeeded() async {
    final jadwalProvider = context.read<JadwalShiftProvider>();
    if (jadwalProvider.todayShift != null) return;

    final cachedShift = await DatabaseHelper.instance.getCachedTodayShift();
    if (cachedShift == null) return;

    jadwalProvider.setCachedTodayShift(cachedShift);
  }

  @override
  void dispose() {
    _absensiProvider?.removeListener(_onAbsensiProviderChanged);
    _lokasiProvider?.removeListener(_onLokasiProviderChanged);
    super.dispose();
  }

  void _onLokasiProviderChanged() {
    if (!mounted) return;
    final lokasiProvider = _lokasiProvider;
    if (lokasiProvider == null) return;

    final coord = lokasiProvider.currentCoordinate;
    if (coord != null) {
      final changed =
          (_lastCenteredLat != coord.latitude) ||
          (_lastCenteredLng != coord.longitude);

      if (changed) {
        _lastCenteredLat = coord.latitude;
        _lastCenteredLng = coord.longitude;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(LatLng(coord.latitude, coord.longitude), _zoom);
        });
      }
    }

    final event = lokasiProvider.uiEvent;
    if (event == null) return;

    lokasiProvider.consumeUiEvent();

    String confirmText = 'OK';
    if (event.action == LokasiUiAction.openLocationSettings) {
      confirmText = 'Buka Pengaturan Lokasi';
    } else if (event.action == LokasiUiAction.openAppSettings) {
      confirmText = 'Buka Settings';
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: event.title,
      text: event.message,
      confirmBtnText: confirmText,
      onConfirmBtnTap: () {
        Navigator.of(context, rootNavigator: true).pop();

        if (event.action == LokasiUiAction.openLocationSettings) {
          lokasiProvider.openLocationSettings();
        } else if (event.action == LokasiUiAction.openAppSettings) {
          lokasiProvider.openAppSettings();
        }
      },
    );
  }

  void _onAbsensiProviderChanged() {
    if (!mounted) return;
    final absensiProvider = _absensiProvider;
    if (absensiProvider == null) return;

    final event = absensiProvider.uiEvent;
    if (event == null) return;

    absensiProvider.consumeUiEvent();

    if (event.type == AbsensiUiEventType.loading) {
      if (_absensiLoadingDialogVisible) return;
      _absensiLoadingDialogVisible = true;

      QuickAlert.show(
        context: context,
        type: QuickAlertType.loading,
        title: event.title,
        text: event.message,
        barrierDismissible: false,
      );
      return;
    }

    if (_absensiLoadingDialogVisible) {
      _absensiLoadingDialogVisible = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (event.type == AbsensiUiEventType.success) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: event.title,
        text: event.message,
        confirmBtnText: event.confirmText ?? 'OK',
        onConfirmBtnTap: () {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context).maybePop();
        },
      );
      return;
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: event.title,
      text: event.message,
      confirmBtnText: event.confirmText ?? 'Coba Lagi',
    );
  }

  Future<void> _onTapRecenter() async {
    await context.read<LokasiProvider>().refreshCurrentLocationAndNearest();
  }

  Future<void> _onTapVerifikasiWajah() async {
    final File? photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const FaceDetectionScreen()),
    );

    if (!mounted || photo == null) return;

    final lokasiProvider = context.read<LokasiProvider>();
    final coord = lokasiProvider.currentCoordinate;
    final offlineProvider = context.read<OfflineProvider>();

    await context.read<AbsensiProvider>().submitCheckInWithFace(
      offlineProvider: offlineProvider,
      imageFile: photo,
      locationId: lokasiProvider.selectedLocation?.idLokasi,
      lat: coord?.latitude,
      lng: coord?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = context.watch<AbsensiProvider>();
    final jadwalProvider = context.watch<JadwalShiftProvider>();
    final lokasiProvider = context.watch<LokasiProvider>();
    final selectedLocation = lokasiProvider.selectedLocation;

    final coord = lokasiProvider.currentCoordinate;
    final markerPosition = coord != null
        ? LatLng(coord.latitude, coord.longitude)
        : _fallbackCenter;

    final statusItem = absensiProvider.status?.item;
    final bool isAlreadyCheckedIn = statusItem?.waktuMasuk != null;
    final bool hasPendingCheckIn = absensiProvider.hasLocalPendingCheckIn;

    String displayStatus = 'Belum\nabsen';
    Color statusColor = const Color(0xFFE85A5A);

    if (isAlreadyCheckedIn) {
      displayStatus = statusItem?.statusMasuk ?? "TEPAT";
      if (displayStatus.toUpperCase().contains('TERLAMBAT')) {
        statusColor = Colors.redAccent;
      } else {
        statusColor = const Color(0xFF57B87B);
      }
    }

    final distanceInMeters = lokasiProvider.distanceToSelectedMeters;
    final isWithinRadius = lokasiProvider.isWithinSelectedRadius;

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
              initialCenter: markerPosition,
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
                      radius: selectedLocation.radius.toDouble(),
                      useRadiusInMeter: true,
                      color: const Color(0xFF57B87B).withOpacity(0.2),
                      borderColor: const Color(0xFF57B87B),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: markerPosition,
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
              showOfflineBadge: hasPendingCheckIn,
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
              icon: lokasiProvider.isLocating
                  ? Icons.hourglass_top
                  : Icons.my_location,
              onTap: lokasiProvider.isLocating ? () {} : _onTapRecenter,
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
                  ? _onTapVerifikasiWajah
                  : null,
            ),
          ),
        ],
      ),
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
  final bool showOfflineBadge;

  const _InfoCard({
    required this.tanggal,
    required this.sekolah,
    required this.status,
    required this.statusColor,
    required this.isLoadingJadwal,
    required this.jadwalShift,
    required this.showOfflineBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE49A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        if (showOfflineBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF57B87B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'OFFLINE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
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
