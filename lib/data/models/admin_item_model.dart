class AdminItemModel {
  final int id;
  final String name;
  final String brand;
  final String categoryName;
  final String description;
  final num dailyPrice;
  final num depositAmount;
  final String status;
  final String imageUrl;
  final DateTime? createdAt;

  const AdminItemModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryName,
    required this.description,
    required this.dailyPrice,
    required this.depositAmount,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
  });

  factory AdminItemModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] ?? json['categories'];
    final primaryImage = json['primary_image'] ?? json['primaryImage'];

    return AdminItemModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Barang',
      brand: json['brand']?.toString() ?? '-',
      categoryName: category is Map<String, dynamic>
          ? category['name']?.toString() ?? '-'
          : json['category_name']?.toString() ?? '-',
      description: json['description']?.toString() ?? '',
      dailyPrice: _toNum(
        json['daily_price'] ??
            json['dailyPrice'] ??
            json['price_per_day'] ??
            json['rental_price'],
      ),
      depositAmount: _toNum(
        json['deposit_amount'] ?? json['depositAmount'] ?? json['deposit'],
      ),
      status: json['status']?.toString() ?? '-',
      imageUrl: _parseImageUrl(json, primaryImage),
      createdAt: _toDateTime(json['created_at']),
    );
  }

  bool get isAvailable => status == 'available';

  bool get isUnavailable {
    return status == 'unavailable' ||
        status == 'rented' ||
        status == 'maintenance';
  }

  static String _parseImageUrl(
    Map<String, dynamic> json,
    Object? primaryImage,
  ) {
    String url = '';

    if (primaryImage is Map<String, dynamic>) {
      url =
          primaryImage['public_url']?.toString() ??
          primaryImage['publicUrl']?.toString() ??
          primaryImage['image_url']?.toString() ??
          '';
    }

    url = url.isNotEmpty
        ? url
        : json['image_url']?.toString() ??
              json['imageUrl']?.toString() ??
              json['photo_url']?.toString() ??
              '';

    if (url.contains('example.com')) return '';

    return url;
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

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
