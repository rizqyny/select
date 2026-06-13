import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/item_model.dart';

class CustomerItemCard extends StatelessWidget {
  final ItemModel item;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onRentTap;
  final double rating;

  const CustomerItemCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onRentTap,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImage(item);
    final isAvailable = _resolveAvailability(item);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.45,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.black.withOpacity(0.05),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _ImageFallback(),
                            )
                          : const _ImageFallback(),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? Colors.red
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFF8B400),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFFE8F8EE)
                              : const Color(0xFFFFE8E8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isAvailable ? 'Tersedia' : 'Tidak tersedia',
                          style: TextStyle(
                            color: isAvailable
                                ? const Color(0xFF30A46C)
                                : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resolveDescription(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'HARGA PER HARI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.rupiah(item.dailyPrice),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const TextSpan(
                                text: '/hari',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: isAvailable ? onRentTap : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Sewa',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImage(ItemModel item) {
    return item.imageUrl;
  }

  bool _resolveAvailability(ItemModel item) {
    try {
      final dynamic raw = item.isAvailable;
      if (raw is bool) return raw;
      return true;
    } catch (_) {
      return true;
    }
  }

  String _resolveDescription(ItemModel item) {
    try {
      final dynamic raw = item.description;
      final text = raw?.toString() ?? '';
      if (text.trim().isNotEmpty) return text;
      return 'Barang elektronik berkualitas untuk kebutuhanmu.';
    } catch (_) {
      return 'Barang elektronik berkualitas untuk kebutuhanmu.';
    }
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withOpacity(0.05),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
