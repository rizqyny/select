import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/favorites_provider.dart';

class FavoriteIconButton extends ConsumerWidget {
  final int itemId;
  final Color? color;
  final Color? activeColor;

  const FavoriteIconButton({
    super.key,
    required this.itemId,
    this.color,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesControllerProvider);

    final value = favoritesState.asData?.value;
    final isFavorite = value?.isFavorite(itemId) ?? false;
    final isUpdating = value?.updatingItemId == itemId;

    return IconButton(
      tooltip: isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
      onPressed: isUpdating
          ? null
          : () async {
              final success = await ref
                  .read(favoritesControllerProvider.notifier)
                  .toggleFavorite(itemId);

              if (!context.mounted) return;

              if (!success) {
                final latestValue = ref
                    .read(favoritesControllerProvider)
                    .asData
                    ?.value;

                final message =
                    latestValue?.errorMessage ?? 'Gagal memperbarui favorit.';

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
      icon: isUpdating
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            )
          : Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite
                  ? activeColor ?? AppColors.danger
                  : color ?? AppColors.textPrimary,
            ),
    );
  }
}
