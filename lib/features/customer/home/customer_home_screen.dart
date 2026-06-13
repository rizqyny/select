import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../notifications/providers/device_token_provider.dart';
import 'providers/customer_home_provider.dart';
import 'widgets/customer_category_chip.dart';
import 'widgets/customer_item_card.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(deviceTokenControllerProvider.notifier).registerDevice();
    });

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(customerHomeControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  IconData _iconForCategory(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('handphone') || lower.contains('hp')) {
      return Icons.smartphone_rounded;
    }

    if (lower.contains('camera') || lower.contains('kamera')) {
      return Icons.camera_alt_outlined;
    }

    if (lower.contains('audio')) {
      return Icons.speaker_outlined;
    }

    if (lower.contains('gaming') || lower.contains('game')) {
      return Icons.sports_esports_outlined;
    }

    if (lower.contains('aksesoris') || lower.contains('aksesori')) {
      return Icons.headphones_outlined;
    }

    if (lower.contains('laptop') || lower.contains('komputer')) {
      return Icons.laptop_mac_outlined;
    }

    return Icons.widgets_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(customerHomeControllerProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: homeState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => _ErrorState(
            message: readableError(error),
            onRetry: () =>
                ref.read(customerHomeControllerProvider.notifier).refresh(),
          ),
          data: (state) {
            final featuredItem = state.items.isNotEmpty
                ? state.items.first
                : null;

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(customerHomeControllerProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _HeaderSection(
                    userName: user?.fullName.isNotEmpty == true
                        ? user!.fullName
                        : 'Customer',
                    onNotificationTap: () =>
                        context.push('/customer/notifications'),
                    onLogoutTap: _logout,
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari kamera, laptop, atau lainnya...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (featuredItem != null)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: _FeaturedBanner(
                        itemName: featuredItem.name,
                        description:
                            'Barang Favorit yang sering disewa pelanggan lain.',
                        imageUrl: _safeImage(featuredItem),
                      ),
                    ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Kategori',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        CustomerCategoryChip(
                          label: 'Semua',
                          icon: Icons.grid_view_rounded,
                          isSelected: state.selectedCategoryId == null,
                          onTap: () {
                            ref
                                .read(customerHomeControllerProvider.notifier)
                                .setCategory(null);
                          },
                        ),
                        ...state.categories.map(
                          (category) => CustomerCategoryChip(
                            label: category.name,
                            icon: _iconForCategory(category.name),
                            isSelected: state.selectedCategoryId == category.id,
                            onTap: () {
                              ref
                                  .read(customerHomeControllerProvider.notifier)
                                  .setCategory(category.id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (state.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.selectedCategoryId == null
                              ? 'Semua Barang'
                              : _selectedCategoryName(state),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (state.isLoadingItems)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (state.items.isEmpty)
                    const _EmptyItemState()
                  else
                    ...state.items.map(
                      (item) => CustomerItemCard(
                        item: item,
                        rating: _safeRating(item),
                        isFavorite: state.favoriteItemIds.contains(item.id),
                        onTap: () => context.push('/customer/items/${item.id}'),
                        onRentTap: () =>
                            context.push('/customer/items/${item.id}'),
                        onFavoriteTap: () async {
                          await ref
                              .read(customerHomeControllerProvider.notifier)
                              .toggleFavorite(item);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _selectedCategoryName(CustomerHomeState state) {
    final selected = state.categories.where(
      (e) => e.id == state.selectedCategoryId,
    );
    if (selected.isEmpty) return 'Barang Favorit';
    return selected.first.name;
  }

  static String _safeImage(dynamic item) {
    try {
      final imageUrl = item.imageUrl?.toString() ?? '';
      return imageUrl;
    } catch (_) {
      return '';
    }
  }

  static double _safeRating(dynamic item) {
    try {
      final raw = item.averageRating ?? item.rating ?? 4.8;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 4.8;
    } catch (_) {
      return 4.8;
    }
  }
}

class _HeaderSection extends StatelessWidget {
  final String userName;
  final VoidCallback onNotificationTap;
  final VoidCallback onLogoutTap;

  const _HeaderSection({
    required this.userName,
    required this.onNotificationTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = userName.trim().isEmpty
        ? 'Customer'
        : userName.trim().split(' ').first;

    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.black,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Halo,\n',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: firstName,
                  style: const TextStyle(
                    fontSize: 24,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          onPressed: onLogoutTap,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  final String itemName;
  final String description;
  final String imageUrl;

  const _FeaturedBanner({
    required this.itemName,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TERPOPULER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 155,
            height: double.infinity,
            child: imageUrl.trim().isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _BannerFallback();
                    },
                  )
                : const _BannerFallback(),
          ),
        ],
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white12,
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white54, size: 40),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: AppColors.danger,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _EmptyItemState extends StatelessWidget {
  const _EmptyItemState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada barang yang sesuai.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Coba ubah kata kunci pencarian atau pilih kategori lain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
