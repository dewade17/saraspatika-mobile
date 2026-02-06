import 'package:geolocator/geolocator.dart';

enum LocationUserAction { openLocationSettings, openAppSettings }

abstract class LocationServiceException implements Exception {
  final String message;
  final LocationUserAction? suggestedAction;

  const LocationServiceException(this.message, {this.suggestedAction});

  @override
  String toString() => message;
}

class LocationServicesDisabledException extends LocationServiceException {
  const LocationServicesDisabledException()
    : super(
        'Location services (GPS) tidak aktif.',
        suggestedAction: LocationUserAction.openLocationSettings,
      );
}

class LocationPermissionDeniedException extends LocationServiceException {
  const LocationPermissionDeniedException() : super('Izin lokasi ditolak.');
}

class LocationPermissionDeniedForeverException
    extends LocationServiceException {
  const LocationPermissionDeniedForeverException()
    : super(
        'Izin lokasi ditolak permanen. Aktifkan lewat Settings.',
        suggestedAction: LocationUserAction.openAppSettings,
      );
}

class MockLocationDetectedException extends LocationServiceException {
  const MockLocationDetectedException()
    : super('Lokasi palsu terdeteksi (Mock Location / Fake GPS).');
}

class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate({required this.latitude, required this.longitude});
}

class LocationService {
  const LocationService();

  Future<Position> determinePosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );

    if (pos.isMocked) {
      throw const MockLocationDetectedException();
    }

    return pos;
  }

  Future<GeoCoordinate> getVerifiedCoordinate({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    final pos = await determinePosition(accuracy: accuracy);
    return GeoCoordinate(latitude: pos.latitude, longitude: pos.longitude);
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
