import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/models/review_model.dart';
import '../providers/item_detail_provider.dart';

class ItemDetailScreen extends ConsumerWidget {
  final int itemId;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
  });

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(itemDetailControllerProvider(itemId).notifier)
          .toggleFavorite();

      if (!context.mounted) return;

      final state = ref.read(itemDetailControllerProvider(itemId)).value;
      final isFavorite = state?.isFavorite == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'Produk berhasil ditambahkan ke favorit.'
                : 'Produk berhasil dihapus dari favorit.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(readableError(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showBookingComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur booking akan dibuat pada Part 5.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(itemDetailControllerProvider(itemId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
        error: (error, stackTrace) => _DetailErrorState(
          message: readableError(error),
          onRetry: () {
            ref.read(itemDetailControllerProvider(itemId).notifier).refresh();
          },
        ),
        data: (state) {
          final item = state.item;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 330,
                pinned: true,
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.textPrimary,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      backgroundColor: AppColors.white,
                      child: state.isUpdatingFavorite
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : IconButton(
                              onPressed: () => _toggleFavorite(context, ref),
                              icon: Icon(
                                state.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: state.isFavorite
                                    ? AppColors.danger
                                    : AppColors.black,
                              ),
                            ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProductImage(item: item),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductMainInfo(item: item),
                      const SizedBox(height: 22),
                      _DescriptionSection(item: item),
                      const SizedBox(height: 22),
                      _SpecificationSection(item: item),
                      const SizedBox(height: 22),
                      _ReviewSection(reviews: state.reviews),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: detailState.maybeWhen(
        data: (state) {
          final item = state.item;

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      CurrencyFormatter.dailyPrice(item.dailyPrice),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppButton(
                      text: item.isAvailable ? 'Booking' : 'Tidak Tersedia',
                      backgroundColor:
                          item.isAvailable ? AppColors.black : AppColors.border,
                      foregroundColor: item.isAvailable
                          ? AppColors.white
                          : AppColors.textSecondary,
                      onPressed: item.isAvailable
                          ? () => _showBookingComingSoon(context)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ItemModel item;

  const _ProductImage({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;

    if (imageUrl.isEmpty) {
      return Container(
        color: AppColors.input,
        child: const Center(
          child: Icon(
            Icons.devices_other_rounded,
            color: AppColors.textSecondary,
            size: 80,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        return Container(
          color: AppColors.input,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        );
      },
      errorWidget: (context, url, error) {
        return Container(
          color: AppColors.input,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.textSecondary,
              size: 70,
            ),
          ),
        );
      },
    );
  }
}

class _ProductMainInfo extends StatelessWidget {
  final ItemModel item;

  const _ProductMainInfo({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBadge(status: item.status),
          const SizedBox(height: 14),
          Text(
            item.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${item.brand} • ${item.model}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _InfoPill(
                icon: Icons.category_rounded,
                label: item.categoryName,
              ),
              const SizedBox(width: 10),
              _InfoPill(
                icon: Icons.qr_code_rounded,
                label: item.serialNumber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final ItemModel item;

  const _DescriptionSection({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Deskripsi',
      child: Text(
        item.description.isEmpty
            ? 'Belum ada deskripsi untuk produk ini.'
            : item.description,
        style: const TextStyle(
          color: AppColors.textSecondary,
          height: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpecificationSection extends StatelessWidget {
  final ItemModel item;

  const _SpecificationSection({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final specs = item.specifications.entries.toList();

    return _SectionCard(
      title: 'Spesifikasi',
      child: specs.isEmpty
          ? const Text(
              'Spesifikasi belum tersedia.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: specs.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final List<ReviewModel> reviews;

  const _ReviewSection({
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Review',
      child: reviews.isEmpty
          ? const Text(
              'Belum ada review untuk produk ini.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: reviews.map((review) {
                return _ReviewTile(review: review);
              }).toList(),
            ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ReviewTile({
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.black,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.input,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 17,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withOpacity(0.12)
            : AppColors.warning.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAvailable ? 'Tersedia' : status,
        style: TextStyle(
          color: isAvailable ? AppColors.success : AppColors.warning,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 48,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Gagal memuat detail',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Coba Lagi',
                  icon: Icons.refresh_rounded,
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}