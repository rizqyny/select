import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';

class NativeCameraScreen extends StatefulWidget {
  final String title;
  final bool showKtpFrame;

  const NativeCameraScreen({
    super.key,
    this.title = 'Ambil Foto',
    this.showKtpFrame = true,
  });

  @override
  State<NativeCameraScreen> createState() => _NativeCameraScreenState();
}

class _NativeCameraScreenState extends State<NativeCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  bool _isLoading = true;
  bool _isTakingPicture = false;
  bool _flashOn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameraPermission = await Permission.camera.request();

      if (!cameraPermission.isGranted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Izin kamera belum diberikan.';
        });
        return;
      }

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kamera tidak ditemukan.';
        });
        return;
      }

      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      await controller.setFlashMode(FlashMode.off);

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal membuka kamera: $error';
      });
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return;

    try {
      _flashOn = !_flashOn;

      await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);

      if (!mounted) return;

      setState(() {});
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return;

    if (_isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final file = await controller.takePicture();

      if (!mounted) return;

      Navigator.pop(context, file.path);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isTakingPicture = false;
        _errorMessage = 'Gagal mengambil foto: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage != null
            ? _ErrorView(message: _errorMessage!, onRetry: _initCamera)
            : Stack(
                children: [
                  Positioned.fill(
                    child: controller == null || !controller.value.isInitialized
                        ? const SizedBox.shrink()
                        : CameraPreview(controller),
                  ),

                  Positioned(
                    left: 16,
                    right: 16,
                    top: 12,
                    child: Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _CircleButton(
                          icon: _flashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          onTap: _toggleFlash,
                        ),
                      ],
                    ),
                  ),

                  if (widget.showKtpFrame)
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.84,
                        height: 230,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Posisikan KTP di dalam area ini',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (!widget.showKtpFrame)
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 120,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Pastikan seluruh kondisi barang terlihat jelas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 28,
                    child: Center(
                      child: GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 5,
                            ),
                          ),
                          child: _isTakingPicture
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: AppColors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.black,
                                  size: 34,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.primary,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
