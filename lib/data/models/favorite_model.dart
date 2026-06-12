class FavoriteItemModel {
  final int favoriteId;
  final int itemId;
  final String name;
  final String brand;
  final String status;
  final double dailyPrice;
  final String imageUrl;

  const FavoriteItemModel({
    required this.favoriteId,
    required this.itemId,
    required this.name,
    required this.brand,
    required this.status,
    required this.dailyPrice,
    required this.imageUrl,
  });

  factory FavoriteItemModel.fromJson(Map<String, dynamic> json) {
    final item = _extractItem(json);

    return FavoriteItemModel(
      favoriteId: _toInt(json['id']),
      itemId: _toInt(
        json['item_id'] ?? json['itemId'] ?? item['id'] ?? item['item_id'],
      ),
      name: item['name']?.toString() ?? '-',
      brand: item['brand']?.toString() ?? '-',
      status: item['status']?.toString() ?? '-',
      dailyPrice: _toDouble(
        item['daily_price'] ??
            item['dailyPrice'] ??
            item['price'] ??
            item['rental_price'],
      ),
      imageUrl: _extractImageUrl(item),
    );
  }

  static Map<String, dynamic> _extractItem(Map<String, dynamic> json) {
    final item =
        json['item'] ??
        json['items'] ??
        json['electronic_item'] ??
        json['electronicItem'];

    if (item is Map<String, dynamic>) {
      return item;
    }

    return json;
  }

  static String _extractImageUrl(Map<String, dynamic> item) {
    final direct =
        item['image_url'] ??
        item['imageUrl'] ??
        item['primary_image_url'] ??
        item['primaryImageUrl'] ??
        item['public_url'];

    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }

    final images = item['images'] ?? item['item_images'] ?? item['itemImages'];

    if (images is List && images.isNotEmpty) {
      final first = images.first;

      if (first is Map<String, dynamic>) {
        final url =
            first['image_url'] ??
            first['imageUrl'] ??
            first['public_url'] ??
            first['publicUrl'];

        if (url != null && url.toString().trim().isNotEmpty) {
          return url.toString();
        }
      }
    }

    return '';
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;

    return 0;
  }
}
