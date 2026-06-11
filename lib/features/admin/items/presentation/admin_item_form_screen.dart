import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_items_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/admin_item_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../providers/admin_items_provider.dart';

final adminItemCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(itemRepositoryProvider).fetchCategories();
});

class AdminItemFormScreen extends ConsumerStatefulWidget {
  final AdminItemModel? item;

  const AdminItemFormScreen({super.key, this.item});

  @override
  ConsumerState<AdminItemFormScreen> createState() =>
      _AdminItemFormScreenState();
}

class _AdminItemFormScreenState extends ConsumerState<AdminItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dailyPriceController;
  late final TextEditingController _serialNumberController;

  final _picker = ImagePicker();

  int? _categoryId;
  String _status = 'available';
  File? _imageFile;
  bool _isSaving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');
    _brandController = TextEditingController(
      text: item?.brand == '-' ? '' : item?.brand ?? '',
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _dailyPriceController = TextEditingController(
      text: item == null || item.dailyPrice <= 0
          ? ''
          : item.dailyPrice.toStringAsFixed(0),
    );
    _serialNumberController = TextEditingController(
      text: item?.serialNumber ?? '',
    );

    _categoryId = item?.categoryId == 0 ? null : item?.categoryId;
    _status = item?.status == '-' ? 'available' : item?.status ?? 'available';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _dailyPriceController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null || _categoryId == 0) {
      _showError('Kategori wajib dipilih.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? uploadedImagePath;

      if (_imageFile != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = _isEdit
            ? 'item-${widget.item!.id}-$timestamp.jpg'
            : 'item-new-$timestamp.jpg';

        uploadedImagePath = await ref
            .read(storageRepositoryProvider)
            .uploadPrivateFile(
              file: _imageFile!,
              bucket: 'item-images',
              path: 'items/$fileName',
              contentType: 'image/jpeg',
            );
      }

      final repository = ref.read(adminItemRepositoryProvider);

      if (_isEdit) {
        await repository.updateItem(
          id: widget.item!.id,
          name: _nameController.text,
          brand: _brandController.text,
          serialNumber: _serialNumberController.text,
          categoryId: _categoryId!,
          description: _descriptionController.text,
          dailyPrice: _parseNumber(_dailyPriceController.text),
          status: _status,
          imagePath: uploadedImagePath,
        );
      } else {
        await repository.createItem(
          name: _nameController.text,
          brand: _brandController.text,
          serialNumber: _serialNumberController.text,
          categoryId: _categoryId!,
          description: _descriptionController.text,
          dailyPrice: _parseNumber(_dailyPriceController.text),
          status: _status,
          imagePath: uploadedImagePath,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Barang berhasil diperbarui.'
                : 'Barang berhasil ditambahkan.',
          ),
        ),
      );

      ref.invalidate(adminItemsControllerProvider);

      if (!mounted) return;

      context.go('/admin/items');
    } catch (error) {
      if (!mounted) return;

      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  num _parseNumber(String value) {
    final clean = value
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    return num.tryParse(clean) ?? 0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(adminItemCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Barang' : 'Tambah Barang')),
      body: categoriesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) {
          return Center(
            child: Text(
              'Gagal memuat kategori: $error',
              textAlign: TextAlign.center,
            ),
          );
        },
        data: (categories) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
              children: [
                _ImagePickerBox(
                  imageFile: _imageFile,
                  imageUrl: widget.item?.imageUrl ?? '',
                  onTap: _pickImage,
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Data Barang',
                  child: Column(
                    children: [
                      _TextField(
                        controller: _nameController,
                        label: 'Nama Barang',
                        hint: 'Contoh: Kamera Canon EOS M50',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama barang wajib diisi';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _TextField(
                        controller: _brandController,
                        label: 'Brand',
                        hint: 'Contoh: Canon',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Brand wajib diisi';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _TextField(
                        controller: _serialNumberController,
                        label: 'Serial Number',
                        hint: 'Contoh: SN-CANON-M50-001',
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) {
                            return 'Serial number wajib diisi';
                          }

                          if (text.length > 100) {
                            return 'Serial number maksimal 100 karakter';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        decoration: _inputDecoration(
                          label: 'Kategori',
                          hint: 'Pilih kategori',
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _categoryId = value;
                                });
                              },
                        validator: (value) {
                          if (value == null || value == 0) {
                            return 'Kategori wajib dipilih';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: _inputDecoration(
                          label: 'Status',
                          hint: 'Pilih status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'available',
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(
                            value: 'maintenance',
                            child: Text('Maintenance'),
                          ),
                          DropdownMenuItem(
                            value: 'unavailable',
                            child: Text('Unavailable'),
                          ),
                          DropdownMenuItem(
                            value: 'rented',
                            child: Text('Rented'),
                          ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null) return;

                                setState(() {
                                  _status = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Harga',
                  child: Column(
                    children: [
                      _TextField(
                        controller: _dailyPriceController,
                        label: 'Harga Sewa per Hari',
                        hint: 'Contoh: 75000',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_parseNumber(value ?? '') <= 0) {
                            return 'Harga sewa wajib lebih dari 0';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Deskripsi',
                  child: _TextField(
                    controller: _descriptionController,
                    label: 'Deskripsi Barang',
                    hint: 'Tuliskan detail kondisi atau spesifikasi barang',
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Deskripsi wajib diisi';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: AppButton(
            text: _isEdit ? 'Simpan Perubahan' : 'Tambah Barang',
            icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.white,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final File? imageFile;
  final String imageUrl;
  final VoidCallback onTap;

  const _ImagePickerBox({
    required this.imageFile,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (imageFile != null) {
      child = Image.file(imageFile!, fit: BoxFit.cover);
    } else if (imageUrl.trim().isNotEmpty) {
      child = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
      );
    } else {
      child = _placeholder();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.input,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_rounded, color: AppColors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Foto',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.textSecondary,
          size: 54,
        ),
        SizedBox(height: 12),
        Text(
          'Tambah Foto Barang',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Klik untuk memilih gambar dari galeri',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label: label, hint: hint),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppColors.input,
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
  );
}
