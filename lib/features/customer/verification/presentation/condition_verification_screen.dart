import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/device/widgets/native_camera_screen.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/condition_verification_provider.dart';

class ConditionVerificationScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final int itemId;
  final String type;

  const ConditionVerificationScreen({
    super.key,
    required this.bookingId,
    required this.itemId,
    required this.type,
  });

  @override
  ConsumerState<ConditionVerificationScreen> createState() =>
      _ConditionVerificationScreenState();
}

class _ConditionVerificationScreenState
    extends ConsumerState<ConditionVerificationScreen> {
  late final TextEditingController _noteController;
  final _picker = ImagePicker();

  ConditionVerificationArgs get _args {
    return ConditionVerificationArgs(
      bookingId: widget.bookingId,
      itemId: widget.itemId,
      type: widget.type,
    );
  }

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const NativeCameraScreen(
          title: 'Foto Kondisi Barang',
          showKtpFrame: false,
        ),
      ),
    );

    if (path == null || path.trim().isEmpty) return;

    ref
        .read(conditionVerificationControllerProvider(_args).notifier)
        .setImagePath(path);
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    ref
        .read(conditionVerificationControllerProvider(_args).notifier)
        .setImagePath(picked.path);
  }

  Future<void> _submit() async {
    ref
        .read(conditionVerificationControllerProvider(_args).notifier)
        .setNote(_noteController.text);

    final success = await ref
        .read(conditionVerificationControllerProvider(_args).notifier)
        .submit();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi kondisi berhasil dikirim.')),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final verificationState = ref.watch(
      conditionVerificationControllerProvider(args),
    );

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: verificationState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
            children: [
              _InfoBox(type: widget.type),
              const SizedBox(height: 18),
              _PhotoCard(
                imagePath: state.imagePath,
                onCamera: _openCamera,
                onGallery: _pickFromGallery,
              ),
              const SizedBox(height: 18),
              _LocationCard(
                addressText: state.location?.addressText,
                latitude: state.location?.latitude,
                longitude: state.location?.longitude,
                isLoading: state.isGettingLocation,
                onGetLocation: () {
                  ref
                      .read(
                        conditionVerificationControllerProvider(args).notifier,
                      )
                      .getCurrentLocation();
                },
              ),
              const SizedBox(height: 18),
              _NoteCard(controller: _noteController),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 18),
                _MessageBox(message: state.errorMessage!),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: verificationState.maybeWhen(
        data: (state) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: AppButton(
                text: 'Kirim Verifikasi Kondisi',
                icon: Icons.send_rounded,
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                isLoading: state.isSubmitting,
                onPressed: state.canSubmit && !state.isSubmitting
                    ? _submit
                    : null,
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String type;

  const _InfoBox({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Ambil foto kondisi barang saat masa sewa akan berakhir atau saat barang dikembalikan. Pastikan seluruh kondisi barang terlihat jelas.',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String imagePath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PhotoCard({
    required this.imagePath,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Foto Kondisi Barang',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: imagePath.trim().isEmpty
                ? const Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.textSecondary,
                      size: 58,
                    ),
                  )
                : Image.file(File(imagePath), fit: BoxFit.cover),
          ),
          const SizedBox(height: 14),
          AppButton(
            text: 'Ambil Foto',
            icon: Icons.camera_alt_rounded,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.black,
            onPressed: onCamera,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.image_rounded),
              label: const Text(
                'Pilih dari Galeri',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final VoidCallback onGetLocation;

  const _LocationCard({
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.isLoading,
    required this.onGetLocation,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Lokasi GPS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (addressText == null)
            const Text(
              'Lokasi belum diambil.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Text(
              addressText!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Lat: $latitude\nLong: $longitude',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            text: isLoading ? 'Mengambil Lokasi...' : 'Ambil Lokasi GPS',
            icon: Icons.my_location_rounded,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.black,
            isLoading: isLoading,
            onPressed: isLoading ? null : onGetLocation,
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final TextEditingController controller;

  const _NoteCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Catatan Kondisi',
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Contoh: kondisi barang baik, layar aman, charger lengkap.',
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
        ),
      ),
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
