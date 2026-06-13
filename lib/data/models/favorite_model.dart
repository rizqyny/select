class FavoriteItemModel {
  final int id;
  final int itemId;
  final String name;
  final String brand;
  final String imageUrl;
  final num dailyPrice;

  const FavoriteItemModel({
    required this.id,
    required this.itemId,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.dailyPrice,
  });

  factory FavoriteItemModel.fromJson(Map<String, dynamic> json) {
    final rawItem =
        json['item'] ??
        json['items'] ??
        json['item_detail'] ??
        json['itemDetail'];

    final item = rawItem is Map<String, dynamic>
        ? rawItem
        : <String, dynamic>{};

    return FavoriteItemModel(
      id: _toInt(json['id']),
      itemId: _toInt(
        json['item_id'] ?? json['itemId'] ?? item['id'] ?? json['id'],
      ),
      name:
          item['name']?.toString() ??
          json['item_name']?.toString() ??
          json['name']?.toString() ??
          'Barang',
      brand: item['brand']?.toString() ?? json['brand']?.toString() ?? '-',
      imageUrl: _extractImageUrl(json: json, item: item),
      dailyPrice: _toNum(
        item['daily_price'] ??
            item['dailyPrice'] ??
            item['price_per_day'] ??
            item['pricePerDay'] ??
            json['daily_price'] ??
            json['dailyPrice'] ??
            json['price_per_day'] ??
            json['pricePerDay'],
      ),
    );
  }

  static String _extractImageUrl({
    required Map<String, dynamic> json,
    required Map<String, dynamic> item,
  }) {
    final directCandidates = [
      json['image_url'],
      json['imageUrl'],
      json['public_url'],
      json['publicUrl'],
      json['photo_url'],
      json['photoUrl'],
      item['image_url'],
      item['imageUrl'],
      item['public_url'],
      item['publicUrl'],
      item['photo_url'],
      item['photoUrl'],
    ];

    for (final value in directCandidates) {
      final url = value?.toString().trim() ?? '';

      if (url.isNotEmpty && !url.contains('example.com')) {
        return url;
      }
    }

    final primaryImage =
        item['primary_image'] ??
        item['primaryImage'] ??
        json['primary_image'] ??
        json['primaryImage'];

    if (primaryImage is Map<String, dynamic>) {
      final url =
          primaryImage['public_url']?.toString().trim() ??
          primaryImage['publicUrl']?.toString().trim() ??
          primaryImage['image_url']?.toString().trim() ??
          primaryImage['imageUrl']?.toString().trim() ??
          '';

      if (url.isNotEmpty && !url.contains('example.com')) {
        return url;
      }
    }

    final images =
        item['images'] ??
        item['item_images'] ??
        item['itemImages'] ??
        json['images'] ??
        json['item_images'] ??
        json['itemImages'];

    if (images is List && images.isNotEmpty) {
      for (final image in images) {
        if (image is Map<String, dynamic>) {
          final url =
              image['public_url']?.toString().trim() ??
              image['publicUrl']?.toString().trim() ??
              image['image_url']?.toString().trim() ??
              image['imageUrl']?.toString().trim() ??
              '';

          if (url.isNotEmpty && !url.contains('example.com')) {
            return url;
          }
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

  static num _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}
