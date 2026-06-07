import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';

class NativeCameraScreen extends StatefulWidget {
  final String title;
  final String instruction;

  const NativeCameraScreen({
    super.key,
    required this.title,
    this.instruction = 'Pastikan foto terlihat jelas dan tidak buram.',
  });

  @override
  State<NativeCameraScreen> createState() => _NativeCameraScreenState();
}

class _NativeCameraScreenState extends State<NativeCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  bool _isInitializing = true;
  bool _isTakingPicture = false;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final permission = await Permission.camera.request();

      if (!permission.isGranted) {
        setState(() {
          _errorMessage = 'Izin kamera dibutuhkan untuk mengambil foto KTP.';
          _isInitializing = false;
        });
        return;
      }

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Kamera tidak ditemukan.';
          _isInitializing = false;
        });
        return;
      }

      final selectedCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final file = await controller.takePicture();

      if (!mounted) return;

      Navigator.pop(context, file.path);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isTakingPicture = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;

    if (controller == null) return;

    final nextMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;

    try {
      await controller.setFlashMode(nextMode);

      setState(() {
        _flashMode = nextMode;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flash tidak tersedia di kamera ini.')),
      );
    }
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Kamera belum siap.',
          style: TextStyle(color: AppColors.white),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(controller)),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.45),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.45),
                  child: IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _flashMode == FlashMode.off
                          ? Icons.flash_off_rounded
                          : Icons.flash_on_rounded,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.84,
            height: MediaQuery.of(context).size.width * 0.53,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 34,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 6),
                    ),
                    child: _isTakingPicture
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.black,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.black,
                            size: 34,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.black, body: _buildBody());
  }
}
