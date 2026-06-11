import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/device/widgets/native_camera_screen.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/identity_verification_provider.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const IdentityVerificationScreen({super.key, required this.bookingId});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ktpNameController = TextEditingController();
  final _ktpNumberController = TextEditingController();
  final _imagePicker = picker.ImagePicker();

  @override
  void dispose() {
    _ktpNameController.dispose();
    _ktpNumberController.dispose();
    super.dispose();
  }

  Future<void> _openNativeCamera() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) =>
            const NativeCameraScreen(title: 'Foto KTP', showKtpFrame: true),
      ),
    );

    if (result == null || result.isEmpty) return;

    ref
        .read(identityVerificationControllerProvider(widget.bookingId).notifier)
        .setImagePath(result);
  }

  Future<void> _pickFromGalleryFallback() async {
    final image = await _imagePicker.pickImage(
      source: picker.ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    ref
        .read(identityVerificationControllerProvider(widget.bookingId).notifier)
        .setImagePath(image.path);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(identityVerificationControllerProvider(widget.bookingId).notifier)
        .submit();

    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verifikasi KTP berhasil dikirim. Tunggu persetujuan admin.',
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(
      identityVerificationControllerProvider(widget.bookingId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi KTP')),
      body: verificationState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (state) {
          final imagePath = state.imagePath;
          final location = state.location;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
              children: [
                _InfoCard(bookingId: widget.bookingId),
                const SizedBox(height: 18),

                _SectionCard(
                  title: 'Data KTP',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _ktpNameController,
                        enabled: !state.isSubmitting,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_rounded),
                          hintText: 'Nama sesuai KTP',
                        ),
                        onChanged: (value) {
                          ref
                              .read(
                                identityVerificationControllerProvider(
                                  widget.bookingId,
                                ).notifier,
                              )
                              .setKtpName(value);
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama KTP tidak boleh kosong';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ktpNumberController,
                        enabled: !state.isSubmitting,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.badge_rounded),
                          hintText: 'Nomor KTP',
                        ),
                        onChanged: (value) {
                          ref
                              .read(
                                identityVerificationControllerProvider(
                                  widget.bookingId,
                                ).notifier,
                              )
                              .setKtpNumber(value);
                        },
                        validator: (value) {
                          final clean = (value ?? '').replaceAll(
                            RegExp(r'\D'),
                            '',
                          );

                          if (clean.isEmpty) {
                            return 'Nomor KTP tidak boleh kosong';
                          }

                          if (clean.length < 8) {
                            return 'Nomor KTP tidak valid';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _SectionCard(
                  title: 'Foto KTP',
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
                        child: imagePath == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Belum ada foto KTP',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      AppButton(
                        text: 'Ambil Foto KTP',
                        icon: Icons.photo_camera_rounded,
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        onPressed: state.isSubmitting
                            ? null
                            : _openNativeCamera,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: state.isSubmitting
                              ? null
                              : _pickFromGalleryFallback,
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text(
                            'Pilih dari Galeri',
                            style: TextStyle(fontWeight: FontWeight.w800),
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
                ),

                const SizedBox(height: 18),

                _SectionCard(
                  title: 'Lokasi GPS',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      location == null
                          ? const Text(
                              'Lokasi belum diambil.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location.addressText,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Lat: ${location.latitude}\nLong: ${location.longitude}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 14),
                      AppButton(
                        text: state.isGettingLocation
                            ? 'Mengambil Lokasi...'
                            : 'Ambil Lokasi GPS',
                        icon: Icons.my_location_rounded,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.black,
                        isLoading: state.isGettingLocation,
                        onPressed: state.isGettingLocation || state.isSubmitting
                            ? null
                            : () {
                                ref
                                    .read(
                                      identityVerificationControllerProvider(
                                        widget.bookingId,
                                      ).notifier,
                                    )
                                    .getCurrentLocation();
                              },
                      ),
                    ],
                  ),
                ),

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 18),
                  _MessageBox(message: state.errorMessage!),
                ],
              ],
            ),
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
                text: state.isSubmitting
                    ? 'Mengirim Verifikasi...'
                    : 'Kirim Verifikasi KTP',
                icon: Icons.send_rounded,
                backgroundColor: state.canSubmit
                    ? AppColors.black
                    : AppColors.border,
                foregroundColor: state.canSubmit
                    ? AppColors.white
                    : AppColors.textSecondary,
                isLoading: state.isSubmitting,
                onPressed: state.canSubmit ? _submit : null,
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final int bookingId;

  const _InfoCard({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: AppColors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Booking #$bookingId membutuhkan verifikasi KTP terlebih dahulu. '
              'Pembayaran baru tersedia setelah verifikasi disetujui admin.',
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          height: 1.4,
        ),
      ),
    );
  }
}
