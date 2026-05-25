class CapturedLocation {
  final double latitude;
  final double longitude;
  final String addressText;
  final DateTime takenAt;

  const CapturedLocation({
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.takenAt,
  });
}
