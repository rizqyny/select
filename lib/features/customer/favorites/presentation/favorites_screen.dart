import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/favorite_model.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorit Saya'),
      ),
      body: favoritesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: readableError(error),
          onRetry: () {
            ref.read(favoritesControllerProvider.notifier).refresh();
          },
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () {
              return ref.read(favoritesControllerProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 110),
              children: [
                _HeaderCard(total: state.favorites.length),
                const SizedBox(height: 18),

                if (state.errorMessage != null) ...[
                  _MessageBox(message: state.errorMessage!),
                  const SizedBox(height: 14),
                ],

                if (state.favorites.isEmpty)
                  const _EmptyState()
                else
                  ...state.favorites.map(
                    (favorite) {
                      final isUpdating = state.updatingItemId == favorite.itemId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _FavoriteCard(
                          favorite: favorite,
                          isUpdating: isUpdating,
                          onTap: () {
                            context.push('/customer/items/${favorite.itemId}');
                          },
                          onRemove: () {
                            ref
                                .read(favoritesControllerProvider.notifier)
                                .toggleFavorite(favorite.itemId);
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;

  const _HeaderCard({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.black,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$total Barang Favorit',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final FavoriteItemModel favorite;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.favorite,
    required this.isUpdating,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 86,
                height: 86,
                color: AppColors.input,
                child: favorite.imageUrl.isEmpty
                    ? const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textSecondary,
                        size: 34,
                      )
                    : Image.network(
                        favorite.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textSecondary,
                            size: 34,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    favorite.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${favorite.dailyPrice.toStringAsFixed(0)} / hari',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isUpdating ? null : onRemove,
              icon: isUpdating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.danger,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;

  const _MessageBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: AppColors.textSecondary,
            size: 56,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada favorit',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan barang favorit dari halaman detail barang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Center(
        child: Container(
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
                'Gagal memuat favorit',
                textAlign: TextAlign.center,
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
    );
  }
}