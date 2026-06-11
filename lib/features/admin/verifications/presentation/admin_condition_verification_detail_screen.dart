import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/admin_condition_verification_model.dart';
import '../providers/admin_condition_verifications_provider.dart';

class AdminConditionVerificationDetailScreen extends ConsumerWidget {
  final AdminConditionVerificationModel verification;

  const AdminConditionVerificationDetailScreen({
    super.key,
    required this.verification,
  });

  Future<void> _startRent(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mulai Sewa?'),
          content: const Text(
            'Foto kondisi awal akan disetujui dan booking akan dimulai.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Mulai Sewa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminConditionVerificationsControllerProvider.notifier)
        .startRent(
          verificationId: verification.id,
          bookingId: verification.bookingId,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto kondisi disetujui dan masa sewa dimulai.'),
        ),
      );

      Navigator.pop(context);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tolak Verifikasi Kondisi'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Alasan penolakan',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.trim().isEmpty) return;

    final success = await ref
        .read(adminConditionVerificationsControllerProvider.notifier)
        .reject(
          verificationId: verification.id,
          reason: reason,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi kondisi ditolak.'),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminConditionVerificationsControllerProvider);
    final isUpdating = state.value?.updatingId == verification.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kondisi Awal'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
        children: [
          _PhotoSection(verification: verification),
          const SizedBox(height: 18),
          _InfoSection(
            title: 'Data Booking',
            children: [
              _InfoRow('Kode Booking', verification.booking.bookingCode),
              _InfoRow('Status Booking', verification.booking.status),
              _InfoRow('Customer', verification.user.fullName),
              _InfoRow('Email', verification.user.email),
              _InfoRow('Telepon', verification.user.phone),
            ],
          ),
          const SizedBox(height: 18),
          _InfoSection(
            title: 'Data Barang',
            children: [
              _InfoRow('Barang', verification.item.name),
              _InfoRow('Brand', verification.item.brand),
              _InfoRow('Model', verification.item.model),
              _InfoRow('Serial Number', verification.item.serialNumber),
            ],
          ),
          const SizedBox(height: 18),
          _InfoSection(
            title: 'Lokasi & Catatan',
            children: [
              _InfoRow('Alamat', verification.addressText),
              _InfoRow('Latitude', verification.latitude.toString()),
              _InfoRow('Longitude', verification.longitude.toString()),
              _InfoRow('Catatan', verification.note),
              _InfoRow('Status Verifikasi', _statusLabel(verification.status)),
              if (verification.rejectionReason != null)
                _InfoRow('Alasan Ditolak', verification.rejectionReason!),
            ],
          ),
        ],
      ),
      bottomNavigationBar: verification.isPending
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed:
                              isUpdating ? null : () => _reject(context, ref),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Mulai Sewa',
                        icon: Icons.play_arrow_rounded,
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        isLoading: isUpdating,
                        onPressed:
                            isUpdating ? null : () => _startRent(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Text(
                  verification.isApproved
                      ? 'Verifikasi kondisi sudah disetujui.'
                      : 'Verifikasi kondisi sudah ditolak.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: verification.isApproved
                        ? AppColors.success
                        : AppColors.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }
}

class _PhotoSection extends StatelessWidget {
  final AdminConditionVerificationModel verification;

  const _PhotoSection({
    required this.verification,
  });

  Future<String?> _signedUrl() async {
    final bucket = verification.photoBucket.trim().isEmpty
        ? 'condition-photos'
        : verification.photoBucket.trim();

    String path = verification.photoPath.trim();

    if (path.startsWith('$bucket/')) {
      path = path.replaceFirst('$bucket/', '');
    }

    if (path.isEmpty) return null;

    return Supabase.instance.client.storage
        .from(bucket)
        .createSignedUrl(path, 3600);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<String?>(
        future: _signedUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final url = snapshot.data;

          if (url == null || url.isEmpty) {
            return const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.textSecondary,
                size: 58,
              ),
            );
          }

          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                  size: 58,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> children;

  const _InfoSection({
    required this.title,
    required this.children,
  });

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
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(
    this.label,
    this.value,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}