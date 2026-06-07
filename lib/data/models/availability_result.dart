class AvailabilityResult {
  final bool isAvailable;
  final String message;
  final List<int> unavailableItemIds;

  const AvailabilityResult({
    required this.isAvailable,
    required this.message,
    this.unavailableItemIds = const [],
  });

  factory AvailabilityResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final message = json['message']?.toString() ?? '';

    if (data is bool) {
      return AvailabilityResult(isAvailable: data, message: message);
    }

    if (data is Map<String, dynamic>) {
      final availableValue =
          data['available'] ??
          data['is_available'] ??
          data['all_available'] ??
          json['available'] ??
          json['is_available'];

      final unavailableIds = _extractUnavailableIds(data);

      return AvailabilityResult(
        isAvailable: _toBool(availableValue) ?? unavailableIds.isEmpty,
        message:
            data['message']?.toString() ??
            message.ifEmpty(
              unavailableIds.isEmpty
                  ? 'Barang tersedia pada tanggal tersebut.'
                  : 'Beberapa barang tidak tersedia.',
            ),
        unavailableItemIds: unavailableIds,
      );
    }

    final directAvailable = json['available'] ?? json['is_available'];

    return AvailabilityResult(
      isAvailable: _toBool(directAvailable) ?? (json['success'] == true),
      message: message.ifEmpty('Hasil ketersediaan berhasil diproses.'),
    );
  }

  static List<int> _extractUnavailableIds(Map<String, dynamic> json) {
    final raw =
        json['unavailable_item_ids'] ??
        json['unavailableItems'] ??
        json['unavailable_items'];

    if (raw is List) {
      return raw
          .map((value) => _toIntNullable(value))
          .whereType<int>()
          .toList();
    }

    return <int>[];
  }

  static bool? _toBool(Object? value) {
    if (value is bool) return value;

    if (value is String) {
      final lower = value.toLowerCase();

      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }

    return null;
  }

  static int? _toIntNullable(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

extension _StringX on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}
