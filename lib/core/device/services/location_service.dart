import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/captured_location.dart';

class LocationService {
  const LocationService();

  Future<CapturedLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('GPS belum aktif. Aktifkan lokasi terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final addressText = await _getAddressText(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return CapturedLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      addressText: addressText,
      takenAt: DateTime.now(),
    );
  }

  Future<String> _getAddressText({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return 'Lat: $latitude, Long: $longitude';
      }

      final place = placemarks.first;

      final parts = <String>[
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.subAdministrativeArea ?? '',
        place.administrativeArea ?? '',
        place.country ?? '',
      ].where((part) => part.trim().isNotEmpty).toList();

      if (parts.isEmpty) {
        return 'Lat: $latitude, Long: $longitude';
      }

      return parts.join(', ');
    } catch (_) {
      return 'Lat: $latitude, Long: $longitude';
    }
  }
}
