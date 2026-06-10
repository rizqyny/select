import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/error_message.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../data/models/category_model.dart';
import '../../categories/providers/admin_categories_provider.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _showCategoryForm(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? category,
  }) async {
    final nameController = TextEditingController(
      text: category?.name ?? '',
    );

    final descriptionController = TextEditingController(
      text: _categoryDescription(category),
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(22, 22, 22, bottomInset + 22),
          child: _CategoryFormSheet(
            title: category == null ? 'Tambah Kategori' : 'Edit Kategori',
            nameController: nameController,
            descriptionController: descriptionController,
            submitText: category == null ? 'Tambah' : 'Simpan',
          ),
        );
      },
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama kategori wajib diisi.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    bool success;

    if (category == null) {
      success = await ref.read(adminCategoriesControllerProvider.notifier).create(
            name: name,
            description: description,
          );
    } else {
      success = await ref.read(adminCategoriesControllerProvider.notifier).updateCategory(
            id: category.id,
            name: name,
            description: description,
          );
    }

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Kategori berhasil ditambahkan.'
                : 'Kategori berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kategori?'),
          content: Text(
            'Kategori "${category.name}" akan dihapus. Pastikan tidak ada barang yang masih memakai kategori ini.',
          ),
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

    final success =
        await ref.read(adminCategoriesControllerProvider.notifier).delete(
              category.id,
            );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus.'),
        ),
      );
    }
  }

  static String _categoryDescription(CategoryModel? category) {
    if (category == null) return '';

    try {
      final dynamic value = category;
      final description = value.description;

      if (description is String) {
        return description;
      }
    } catch (_) {}

    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(adminCategoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        onPressed: () {
          _showCategoryForm(context, ref);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: categoriesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: readableError(error),
          onRetry: () {
            ref.read(adminCategoriesControllerProvider.notifier).refresh();
          },
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () {
              return ref
                  .read(adminCategoriesControllerProvider.notifier)
                  .refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              children: [
                if (state.errorMessage != null) ...[
                  _MessageBox(message: state.errorMessage!),
                  const SizedBox(height: 14),
                ],
                if (state.categories.isEmpty)
                  const _EmptyState()
                else
                  ...state.categories.map(
                    (category) {
                      final isUpdating = state.updatingId == category.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CategoryCard(
                          category: category,
                          isUpdating: isUpdating,
                          onEdit: () {
                            _showCategoryForm(
                              context,
                              ref,
                              category: category,
                            );
                          },
                          onDelete: () {
                            _confirmDelete(context, ref, category);
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

class _CategoryFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String submitText;

  const _CategoryFormSheet({
    required this.title,
    required this.nameController,
    required this.descriptionController,
    required this.submitText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'Contoh: Kamera',
            filled: true,
            fillColor: AppColors.input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Deskripsi',
            hintText: 'Opsional',
            filled: true,
            fillColor: AppColors.input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AppButton(
          text: submitText,
          icon: Icons.save_rounded,
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.isUpdating,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final description = _descriptionText(category);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          isUpdating
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
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
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
        ],
      ),
    );
  }

  String _descriptionText(CategoryModel category) {
    try {
      final dynamic value = category;
      final description = value.description;

      if (description is String) {
        return description;
      }
    } catch (_) {}

    return '';
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
            Icons.category_outlined,
            color: AppColors.textSecondary,
            size: 54,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada kategori',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kategori barang akan muncul di halaman ini.',
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
                'Gagal memuat kategori',
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