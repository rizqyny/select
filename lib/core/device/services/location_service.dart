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

    final latitude = position.latitude;
    final longitude = position.longitude;

    final addressText = await _safeGetAddressText(
      latitude: latitude,
      longitude: longitude,
    );

    return CapturedLocation(
      latitude: latitude,
      longitude: longitude,
      addressText: addressText,
      takenAt: DateTime.now(),
    );
  }

  Future<String> _safeGetAddressText({
    required double latitude,
    required double longitude,
  }) async {
    final fallback = 'Lat: $latitude, Long: $longitude';

    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 8), onTimeout: () => <Placemark>[]);

      if (placemarks.isEmpty) {
        return fallback;
      }

      final place = placemarks.first;

      final rawParts = <String?>[
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.country,
      ];

      final parts = rawParts
          .where((part) => part != null && part.trim().isNotEmpty)
          .map((part) => part!.trim())
          .toList();

      if (parts.isEmpty) {
        return fallback;
      }

      return parts.join(', ');
    } catch (_) {
      return fallback;
    }
  }
}
