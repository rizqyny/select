import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/admin_item_model.dart';
import '../providers/admin_items_provider.dart';

class AdminItemsScreen extends ConsumerStatefulWidget {
  const AdminItemsScreen({super.key});

  @override
  ConsumerState<AdminItemsScreen> createState() => _AdminItemsScreenState();
}

class _AdminItemsScreenState extends ConsumerState<AdminItemsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedFilter;

  static const _filters = <_ItemFilter>[
    _ItemFilter(label: 'Semua', value: null),
    _ItemFilter(label: 'Handphone', value: 'handphone'),
    _ItemFilter(label: 'Camera', value: 'camera'),
    _ItemFilter(label: 'Audio', value: 'audio'),
    _ItemFilter(label: 'Laptop', value: 'laptop'),
    // _ItemFilter(label: 'Tersedia', value: 'available'),
    // _ItemFilter(label: 'Disewa', value: 'rented'),
    // _ItemFilter(label: 'Maintenance', value: 'maintenance'),
    // _ItemFilter(label: 'Tidak Tersedia', value: 'unavailable'),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(adminItemsControllerProvider.notifier).search(value);
    });
  }

  Future<void> _openCreateItem() async {
    final result = await context.push<bool>('/admin/items/create');

    if (result == true && mounted) {
      ref.read(adminItemsControllerProvider.notifier).refresh();
    }
  }

  Future<void> _openEditItem(AdminItemModel item) async {
    final result = await context.push<bool>(
      '/admin/items/${item.id}/edit',
      extra: item,
    );

    if (result == true && mounted) {
      ref.read(adminItemsControllerProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(AdminItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Hapus Barang?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Barang "${item.name}" akan dihapus dari sistem.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminItemsControllerProvider.notifier)
        .deleteItem(item.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Barang berhasil dihapus.')));
    }
  }

  bool _isCategoryFilter(String? value) {
    return value == 'handphone' ||
        value == 'camera' ||
        value == 'audio' ||
        value == 'laptop';
  }

  List<AdminItemModel> _visibleItems(
    List<AdminItemModel> items,
    String? selectedFilter,
  ) {
    if (!_isCategoryFilter(selectedFilter)) return items;

    final filter = selectedFilter ?? '';

    return items.where((item) {
      final text = '${item.name} ${item.brand} ${item.categoryName}'
          .toLowerCase();

      if (filter == 'handphone') {
        return text.contains('handphone') ||
            text.contains('phone') ||
            text.contains('hp') ||
            text.contains('iphone') ||
            text.contains('samsung');
      }

      if (filter == 'camera') {
        return text.contains('camera') ||
            text.contains('kamera') ||
            text.contains('sony') ||
            text.contains('canon') ||
            text.contains('nikon') ||
            text.contains('fujifilm');
      }

      if (filter == 'audio') {
        return text.contains('audio') ||
            text.contains('speaker') ||
            text.contains('headphone') ||
            text.contains('earphone') ||
            text.contains('mic');
      }

      if (filter == 'laptop') {
        return text.contains('laptop') ||
            text.contains('macbook') ||
            text.contains('asus') ||
            text.contains('lenovo');
      }

      return true;
    }).toList();
  }

  void _setFilter(String? value) {
    setState(() {
      _selectedFilter = value;
    });

    if (_isCategoryFilter(value)) {
      ref.read(adminItemsControllerProvider.notifier).setStatus(null);
      return;
    }

    ref.read(adminItemsControllerProvider.notifier).setStatus(value);
  }

  Future<void> _showFilterSheet(String? selectedValue) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter Barang',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _filters.map((filter) {
                    final selected = selectedValue == filter.value;

                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: selected,
                      selectedColor: AppColors.black,
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.border),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      onSelected: (_) {
                        Navigator.pop(context, filter.value);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    _setFilter(selected);
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(adminItemsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Barang',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-add-item',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        elevation: 0,
        onPressed: _openCreateItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Barang',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: itemsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: readableError(error),
          onRetry: () {
            ref.read(adminItemsControllerProvider.notifier).refresh();
          },
        ),
        data: (state) {
          if (_searchController.text != state.search) {
            _searchController.text = state.search;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          }

          final selectedFilter = _selectedFilter ?? state.selectedStatus;
          final visibleItems = _visibleItems(state.items, selectedFilter);

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(adminItemsControllerProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SearchBox(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FilterButton(
                      onTap: () => _showFilterSheet(selectedFilter),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 9),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = selectedFilter == filter.value;

                      return _FilterChipButton(
                        label: filter.label,
                        isSelected: selected,
                        onTap: () => _setFilter(filter.value),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  _MessageBox(message: state.errorMessage!),
                  const SizedBox(height: 14),
                ],
                if (visibleItems.isEmpty)
                  const _EmptyState()
                else
                  GridView.builder(
                    itemCount: visibleItems.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      final isDeleting = state.deletingId == item.id;

                      return _ItemCard(
                        item: item,
                        isDeleting: isDeleting,
                        onEdit: () => _openEditItem(item),
                        onDelete: () => _confirmDelete(item),
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari barang...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 21,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 20),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.black : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.black : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final AdminItemModel item;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.status == 'available';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _ItemImage(url: item.imageUrl)),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _StatusBadge(status: item.status),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: isDeleting
                          ? Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.white,
                              ),
                              color: AppColors.white,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit();
                                }

                                if (value == 'delete') {
                                  onDelete();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                    ),
                    if (!isAvailable)
                      Positioned.fill(
                        child: Container(
                          color: AppColors.black.withValues(alpha: 0.34),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _subtitle(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: CurrencyFormatter.rupiah(item.dailyPrice),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const TextSpan(
                            text: ' / hari',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
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
      ),
    );
  }

  String _subtitle(AdminItemModel item) {
    final brand = item.brand.trim();
    final category = item.categoryName.trim();

    if (brand.isNotEmpty && brand != '-') return brand;
    if (category.isNotEmpty) return category;

    return 'Barang elektronik';
  }
}

class _ItemImage extends StatelessWidget {
  final String url;

  const _ItemImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return url.trim().isEmpty
        ? const _ImageFallback()
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const _ImageFallback();
            },
          );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.input,
      child: const Center(
        child: Icon(
          Icons.devices_other_rounded,
          color: AppColors.textSecondary,
          size: 34,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: _textColor(status),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _color(String status) {
    switch (status) {
      case 'available':
        return AppColors.primary;
      case 'rented':
      case 'maintenance':
      case 'unavailable':
        return AppColors.white;
      default:
        return AppColors.primary;
    }
  }

  Color _textColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.black;
      case 'rented':
      case 'maintenance':
      case 'unavailable':
        return AppColors.textPrimary;
      default:
        return AppColors.black;
    }
  }

  String _label(String status) {
    switch (status) {
      case 'available':
        return 'TERSEDIA';
      case 'rented':
        return 'DISEWA';
      case 'maintenance':
        return 'SERVIS';
      case 'unavailable':
        return 'NONAKTIF';
      default:
        return status.toUpperCase();
    }
  }
}

class _ItemFilter {
  final String label;
  final String? value;

  const _ItemFilter({required this.label, required this.value});
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
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.devices_other_rounded,
            color: AppColors.textSecondary,
            size: 54,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada barang',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Data barang elektronik akan muncul di halaman ini.',
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
                'Gagal memuat barang',
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
