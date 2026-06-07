class ReviewModel {
  final int id;
  final int rating;
  final String comment;
  final String reviewerName;
  final String? mediaBucket;
  final String? mediaPath;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.mediaBucket,
    required this.mediaPath,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final customer = json['customer'];

    String reviewerName = 'Customer';

    if (user is Map<String, dynamic>) {
      reviewerName =
          user['full_name']?.toString() ??
          user['email']?.toString() ??
          'Customer';
    } else if (customer is Map<String, dynamic>) {
      reviewerName =
          customer['full_name']?.toString() ??
          customer['email']?.toString() ??
          'Customer';
    } else if (json['reviewer_name'] != null) {
      reviewerName = json['reviewer_name'].toString();
    }

    return ReviewModel(
      id: _toInt(json['id']),
      rating: _toInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      reviewerName: reviewerName,
      mediaBucket: json['media_bucket']?.toString(),
      mediaPath: json['media_path']?.toString(),
      createdAt: _toDateTime(json['created_at']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
