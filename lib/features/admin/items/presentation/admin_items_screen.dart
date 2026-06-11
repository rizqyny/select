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

  static const _filters = <_ItemFilter>[
    _ItemFilter(label: 'Semua', value: null),
    _ItemFilter(label: 'Available', value: 'available'),
    _ItemFilter(label: 'Rented', value: 'rented'),
    _ItemFilter(label: 'Maintenance', value: 'maintenance'),
    _ItemFilter(label: 'Unavailable', value: 'unavailable'),
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

  Future<void> _confirmDelete(AdminItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Barang?'),
          content: Text('Barang "${item.name}" akan dihapus dari sistem.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
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

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(adminItemsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Barang')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        onPressed: () async {
          final result = await context.push<bool>('/admin/items/create');

          if (result == true && mounted) {
            ref.read(adminItemsControllerProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
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

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(adminItemsControllerProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = state.selectedStatus == filter.value;

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
                          ref
                              .read(adminItemsControllerProvider.notifier)
                              .setStatus(filter.value);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (state.errorMessage != null) ...[
                  _MessageBox(message: state.errorMessage!),
                  const SizedBox(height: 14),
                ],
                if (state.items.isEmpty)
                  const _EmptyState()
                else
                  ...state.items.map((item) {
                    final isDeleting = state.deletingId == item.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ItemCard(
                        item: item,
                        isDeleting: isDeleting,
                        onDelete: () => _confirmDelete(item),
                        onEdit: () async {
                          final result = await context.push<bool>(
                            '/admin/items/${item.id}/edit',
                            extra: item,
                          );

                          if (result == true && mounted) {
                            ref
                                .read(adminItemsControllerProvider.notifier)
                                .refresh();
                          }
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ItemImage(url: item.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: item.status),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.brand} • ${item.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.dailyPrice(item.dailyPrice),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isDeleting
              ? const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                )
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }

                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  final String url;

  const _ItemImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Icon(
              Icons.devices_other_rounded,
              color: AppColors.textSecondary,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.devices_other_rounded,
                  color: AppColors.textSecondary,
                );
              },
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _color(String status) {
    switch (status) {
      case 'available':
        return AppColors.success;
      case 'rented':
      case 'maintenance':
      case 'unavailable':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _label(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'rented':
        return 'Rented';
      case 'maintenance':
        return 'Maintenance';
      case 'unavailable':
        return 'Unavailable';
      default:
        return status;
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
