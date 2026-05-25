import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../camera/presentation/native_camera_screen.dart';
import '../../location/models/captured_location.dart';
import '../../location/services/location_service.dart';
import '../models/verification_capture_result.dart';

class VerificationCaptureScreen extends StatefulWidget {
  final VerificationCaptureArgs args;

  const VerificationCaptureScreen({
    super.key,
    required this.args,
  });

  @override
  State<VerificationCaptureScreen> createState() =>
      _VerificationCaptureScreenState();
}

class _VerificationCaptureScreenState extends State<VerificationCaptureScreen> {
  final _locationService = const LocationService();
  final _imagePicker = picker.ImagePicker();

  String? _imagePath;
  CapturedLocation? _location;

  bool _isGettingLocation = false;

  Future<void> _openNativeCamera() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => NativeCameraScreen(
          title: widget.args.type.title,
        ),
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() {
      _imagePath = result;
    });
  }

  Future<void> _pickFromGalleryFallback() async {
    final image = await _imagePicker.pickImage(
      source: picker.ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _imagePath = image.path;
    });
  }

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        _location = location;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _finishCapture() {
    final imagePath = _imagePath;
    final location = _location;

    if (imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambil foto terlebih dahulu.'),
        ),
      );
      return;
    }

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambil lokasi GPS terlebih dahulu.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      VerificationCaptureResult(
        imagePath: imagePath,
        location: location,
        type: widget.args.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath;
    final location = _location;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.type.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 230,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(26),
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
                        SizedBox(height: 12),
                        Text(
                          'Belum ada foto',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Kamera Asli',
                    icon: Icons.photo_camera_rounded,
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    onPressed: _openNativeCamera,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _pickFromGalleryFallback,
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

            const SizedBox(height: 26),

            const Text(
              'Lokasi Pengambilan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: location == null
                  ? const Text(
                      'Belum mengambil lokasi GPS.',
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
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Lat: ${location.latitude}\nLong: ${location.longitude}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 14),

            AppButton(
              text: _isGettingLocation ? 'Mengambil Lokasi...' : 'Ambil GPS',
              icon: Icons.my_location_rounded,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.black,
              isLoading: _isGettingLocation,
              onPressed: _isGettingLocation ? null : _getLocation,
            ),

            const SizedBox(height: 24),

            AppButton(
              text: 'Simpan Hasil Capture',
              icon: Icons.check_circle_rounded,
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              onPressed: _finishCapture,
            ),
          ],
        ),
      ),
    );
  }
}