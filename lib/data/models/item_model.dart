import 'category_model.dart';

class ItemModel {
  final int id;
  final int categoryId;
  final CategoryModel? category;
  final String name;
  final String slug;
  final String brand;
  final String model;
  final String serialNumber;
  final String description;
  final num dailyPrice;
  final num replacementValue;
  final String status;
  final bool isActive;
  final Map<String, dynamic> specifications;
  final ItemPrimaryImage? primaryImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double averageRating;
  final int reviewCount;
  final int rentalCount;

  const ItemModel({
    required this.id,
    required this.categoryId,
    required this.category,
    required this.name,
    required this.slug,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.description,
    required this.dailyPrice,
    required this.replacementValue,
    required this.status,
    required this.isActive,
    required this.specifications,
    required this.primaryImage,
    required this.createdAt,
    required this.updatedAt,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.rentalCount = 0,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: _toInt(json['id']),
      categoryId: _toInt(json['category_id']),
      category: json['category'] is Map<String, dynamic>
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      name: json['name']?.toString() ?? '-',
      slug: json['slug']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '-',
      model: json['model']?.toString() ?? '-',
      serialNumber: json['serial_number']?.toString() ?? '-',
      description: json['description']?.toString() ?? '',
      dailyPrice: _toNum(json['daily_price']),
      replacementValue: _toNum(json['replacement_value']),
      status: json['status']?.toString() ?? '-',
      isActive: json['is_active'] == true,
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'] as Map)
          : <String, dynamic>{},
      primaryImage: json['primary_image'] is Map<String, dynamic>
          ? ItemPrimaryImage.fromJson(
              json['primary_image'] as Map<String, dynamic>,
            )
          : null,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      averageRating: _toDouble(
        json['average_rating'] ??
            json['averageRating'] ??
            json['rating_avg'] ??
            json['ratingAvg'] ??
            json['avg_rating'] ??
            json['avgRating'] ??
            json['rating'],
      ),
      reviewCount: _toInt(
        json['review_count'] ??
            json['reviewCount'] ??
            json['reviews_count'] ??
            json['reviewsCount'] ??
            json['_count']?['reviews'],
      ),
      rentalCount: _toInt(
        json['rental_count'] ??
            json['rentalCount'] ??
            json['total_rented'] ??
            json['totalRented'] ??
            json['booking_count'] ??
            json['bookingCount'] ??
            json['bookings_count'] ??
            json['bookingsCount'] ??
            json['_count']?['booking_items'],
      ),
    );
  }

  ItemModel copyWith({
    double? averageRating,
    int? reviewCount,
    int? rentalCount,
  }) {
    return ItemModel(
      id: id,
      categoryId: categoryId,
      category: category,
      name: name,
      slug: slug,
      brand: brand,
      model: model,
      serialNumber: serialNumber,
      description: description,
      dailyPrice: dailyPrice,
      replacementValue: replacementValue,
      status: status,
      isActive: isActive,
      specifications: specifications,
      primaryImage: primaryImage,
      createdAt: createdAt,
      updatedAt: updatedAt,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      rentalCount: rentalCount ?? this.rentalCount,
    );
  }

  String get categoryName => category?.name ?? 'Umum';

  String get imageUrl {
    final url = primaryImage?.publicUrl.trim() ?? '';

    if (url.isEmpty) return '';

    // Supaya tidak error kalau data dummy masih memakai example.com
    if (url.contains('example.com')) return '';

    return url;
  }

  bool get isAvailable => status == 'available';

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

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class ItemPrimaryImage {
  final int id;
  final String storageBucket;
  final String storagePath;
  final String publicUrl;

  const ItemPrimaryImage({
    required this.id,
    required this.storageBucket,
    required this.storagePath,
    required this.publicUrl,
  });

  factory ItemPrimaryImage.fromJson(Map<String, dynamic> json) {
    return ItemPrimaryImage(
      id: _toInt(json['id']),
      storageBucket: json['storage_bucket']?.toString() ?? '',
      storagePath: json['storage_path']?.toString() ?? '',
      publicUrl: json['public_url']?.toString() ?? '',
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
