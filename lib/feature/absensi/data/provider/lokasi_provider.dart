import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/core/services/location_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/lokasi_dto.dart';
import 'package:saraspatika/feature/absensi/data/repository/lokasi_repository.dart';

enum LokasiUiAction { none, openLocationSettings, openAppSettings }

class LokasiUiEvent {
  final String title;
  final String message;
  final LokasiUiAction action;

  const LokasiUiEvent({
    required this.title,
    required this.message,
    this.action = LokasiUiAction.none,
  });
}

class LokasiProvider extends ChangeNotifier {
  LokasiProvider({
    LokasiRepository? repository,
    LocationService? locationService,
  }) : _repository = repository ?? LokasiRepository(),
       _locationService = locationService ?? const LocationService();

  final LokasiRepository _repository;
  final LocationService _locationService;

  bool _loading = false;
  bool _isLocating = false;

  String? _errorMessage;

  List<Lokasi> _locations = const <Lokasi>[];
  Lokasi? _selectedLocation;
  List<LokasiWithDistance> _nearestLocations = const <LokasiWithDistance>[];

  GeoCoordinate? _currentCoordinate;
  double _distanceToSelectedMeters = 0.0;
  bool _isWithinSelectedRadius = false;

  LokasiUiEvent? _uiEvent;

  bool get isLoading => _loading;
  bool get isLocating => _isLocating;

  String? get errorMessage => _errorMessage;

  List<Lokasi> get locations => _locations;
  Lokasi? get selectedLocation => _selectedLocation;

  List<LokasiWithDistance> get nearestLocations => _nearestLocations;

  LokasiWithDistance? get nearestLocationWithDistance =>
      _nearestLocations.isNotEmpty ? _nearestLocations.first : null;

  Lokasi? get nearestLocation => nearestLocationWithDistance?.lokasi;

  GeoCoordinate? get currentCoordinate => _currentCoordinate;

  double get distanceToSelectedMeters => _distanceToSelectedMeters;
  bool get isWithinSelectedRadius => _isWithinSelectedRadius;

  LokasiUiEvent? get uiEvent => _uiEvent;

  void consumeUiEvent() {
    _uiEvent = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    if (_loading == v) return;
    _loading = v;
    notifyListeners();
  }

  void _recomputeProximity() {
    final coord = _currentCoordinate;
    final loc = _selectedLocation;

    if (coord == null || loc == null) {
      _distanceToSelectedMeters = 0.0;
      _isWithinSelectedRadius = false;
      return;
    }

    _distanceToSelectedMeters = Geolocator.distanceBetween(
      coord.latitude,
      coord.longitude,
      loc.latitude,
      loc.longitude,
    );

    _isWithinSelectedRadius = _distanceToSelectedMeters <= loc.radius;
  }

  String _friendlyError(Object e) {
    if (e is StateError) {
      final msg = e.message.toString().trim();
      if (msg.isNotEmpty) return msg;
    }

    if (e is ApiException) {
      final d = e.details;
      if (d is Map) {
        final msg = d['message'] ?? d['error'] ?? d['msg'] ?? d['detail'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (e.statusCode == 400) return 'Input tidak valid.';
      if (e.statusCode == 401) return 'Unauthorized.';
      if (e.statusCode == 404) return 'Data tidak ditemukan.';
      return 'Terjadi kesalahan jaringan/server.';
    }

    if (e is LocationServiceException) {
      return e.message;
    }

    return 'Terjadi kesalahan: $e';
  }

  Future<void> openLocationSettings() =>
      _locationService.openLocationSettings();

  Future<void> openAppSettings() => _locationService.openAppSettings();

  void selectLocation(Lokasi? lokasi) {
    _selectedLocation = lokasi;
    _recomputeProximity();
    notifyListeners();
  }

  Future<LokasiResponse> fetchLocations({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _repository.fetchLocations(
        query: query,
        page: page,
        pageSize: pageSize,
      );
      _locations = res.items;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Lokasi?> fetchLocationById(String idLokasi) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final lokasi = await _repository.fetchLocationById(idLokasi);
      _selectedLocation = lokasi;
      _recomputeProximity();
      notifyListeners();
      return _selectedLocation;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<LokasiWithDistance>> fetchNearestLocations({
    required double latitude,
    required double longitude,
    double? radiusMeters,
    int limit = 1,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final items = await _repository.fetchNearestLocations(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        limit: limit,
      );
      _nearestLocations = items;

      if (_nearestLocations.isNotEmpty) {
        _selectedLocation = _nearestLocations.first.lokasi;
      }

      _recomputeProximity();
      notifyListeners();
      return _nearestLocations;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCurrentLocationAndNearest({int limit = 1}) async {
    if (_isLocating) return;

    _isLocating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final coord = await _locationService.getVerifiedCoordinate();
      _currentCoordinate = coord;

      await fetchNearestLocations(
        latitude: coord.latitude,
        longitude: coord.longitude,
        limit: limit,
      );

      _recomputeProximity();
      notifyListeners();
    } on LocationServicesDisabledException catch (e) {
      _errorMessage = e.message;
      _uiEvent = const LokasiUiEvent(
        title: 'GPS tidak aktif',
        message:
            'Aktifkan Location Services (GPS) agar aplikasi bisa mengambil lokasi untuk absensi.',
        action: LokasiUiAction.openLocationSettings,
      );
      notifyListeners();
    } on LocationPermissionDeniedForeverException catch (e) {
      _errorMessage = e.message;
      _uiEvent = const LokasiUiEvent(
        title: 'Izin lokasi dibutuhkan',
        message:
            'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
        action: LokasiUiAction.openAppSettings,
      );
      notifyListeners();
    } on LocationPermissionDeniedException catch (e) {
      _errorMessage = e.message;
      _uiEvent = const LokasiUiEvent(
        title: 'Izin lokasi ditolak',
        message: 'Izin lokasi diperlukan untuk melakukan absensi.',
      );
      notifyListeners();
    } on MockLocationDetectedException catch (e) {
      _errorMessage = e.message;
      _uiEvent = const LokasiUiEvent(
        title: 'Lokasi Palsu Terdeteksi',
        message:
            'Harap matikan aplikasi Fake GPS atau Mock Location untuk melakukan absensi.',
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _uiEvent = LokasiUiEvent(
        title: 'Gagal mengambil lokasi',
        message: _errorMessage ?? 'Terjadi kesalahan.',
      );
      notifyListeners();
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }
}
