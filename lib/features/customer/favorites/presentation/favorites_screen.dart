import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/favorite_model.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String? _selectedFilter;

  static const List<_FavoriteFilter> _filters = [
    _FavoriteFilter(label: 'Semua', value: null),
    _FavoriteFilter(label: 'Handphone', value: 'handphone'),
    _FavoriteFilter(label: 'Camera', value: 'camera'),
    _FavoriteFilter(label: 'Laptop', value: 'laptop'),
    _FavoriteFilter(label: 'Audio', value: 'audio'),
  ];

  List<FavoriteItemModel> _filteredFavorites(
    List<FavoriteItemModel> favorites,
  ) {
    final selected = _selectedFilter;

    if (selected == null) return favorites;

    return favorites.where((favorite) {
      final text = '${favorite.name} ${favorite.brand}'.toLowerCase();

      if (selected == 'handphone') {
        return text.contains('iphone') ||
            text.contains('samsung') ||
            text.contains('phone') ||
            text.contains('hp') ||
            text.contains('handphone');
      }

      if (selected == 'camera') {
        return text.contains('camera') ||
            text.contains('kamera') ||
            text.contains('sony') ||
            text.contains('canon') ||
            text.contains('nikon');
      }

      if (selected == 'laptop') {
        return text.contains('laptop') ||
            text.contains('macbook') ||
            text.contains('asus') ||
            text.contains('lenovo');
      }

      if (selected == 'audio') {
        return text.contains('audio') ||
            text.contains('speaker') ||
            text.contains('headphone') ||
            text.contains('mic');
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Favorit',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
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
          final filteredFavorites = _filteredFavorites(state.favorites);

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(favoritesControllerProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                _HeaderCard(total: state.favorites.length),
                const SizedBox(height: 18),

                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter.value;

                      return _FilterChipButton(
                        label: filter.label,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter.value;
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                if (state.errorMessage != null) ...[
                  _MessageBox(message: state.errorMessage!),
                  const SizedBox(height: 14),
                ],

                if (state.favorites.isEmpty)
                  const _EmptyState()
                else if (filteredFavorites.isEmpty)
                  const _EmptyFilteredState()
                else
                  ...filteredFavorites.map((favorite) {
                    final isUpdating = state.updatingItemId == favorite.itemId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _FavoriteLargeCard(
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
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteFilter {
  final String label;
  final String? value;

  const _FavoriteFilter({required this.label, required this.value});
}

class _HeaderCard extends StatelessWidget {
  final int total;

  const _HeaderCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Barang Favorit Saya',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'Simpan barang pilihanmu agar mudah ditemukan lagi.'
                      : '$total barang tersimpan untuk disewa nanti.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.black : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.black : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteLargeCard extends StatelessWidget {
  final FavoriteItemModel favorite;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteLargeCard({
    required this.favorite,
    required this.isUpdating,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: favorite.imageUrl.trim().isEmpty
                        ? const _FavoriteImageFallback()
                        : Image.network(
                            favorite.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const _FavoriteImageFallback();
                            },
                          ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: isUpdating ? null : onRemove,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: isUpdating
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.danger,
                                size: 25,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'TERSEDIA',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          favorite.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: Color(0xFFF8B400),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _ratingText(favorite),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _subtitleText(favorite),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _shortPrice(favorite.dailyPrice),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(
                          text: ' / hari',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _subtitleText(FavoriteItemModel favorite) {
    final brand = favorite.brand.trim();

    if (brand.isEmpty || brand == '-') {
      return 'Barang elektronik pilihan yang sudah kamu simpan.';
    }

    return brand;
  }

  static String _ratingText(FavoriteItemModel favorite) {
    final seed = favorite.itemId % 3;

    if (seed == 0) return '5.0';
    if (seed == 1) return '4.9';
    return '4.8';
  }

  static String _shortPrice(num price) {
    if (price >= 1000000) {
      final value = price / 1000000;
      return 'Rp ${_cleanDecimal(value)}jt';
    }

    if (price >= 1000) {
      final value = price / 1000;
      return 'Rp ${_cleanDecimal(value)}rb';
    }

    return CurrencyFormatter.rupiah(price);
  }

  static String _cleanDecimal(num value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _FavoriteImageFallback extends StatelessWidget {
  const _FavoriteImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.input,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textSecondary,
          size: 46,
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;

  const _MessageBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
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
      padding: const EdgeInsets.all(28),
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
            size: 58,
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
            'Simpan barang favorit dari halaman beranda atau detail barang.',
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

class _EmptyFilteredState extends StatelessWidget {
  const _EmptyFilteredState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.textSecondary,
            size: 58,
          ),
          SizedBox(height: 14),
          Text(
            'Tidak ada item di kategori ini',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coba pilih kategori lain atau kembali ke semua favorit.',
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

  const _ErrorState({required this.message, required this.onRetry});

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
