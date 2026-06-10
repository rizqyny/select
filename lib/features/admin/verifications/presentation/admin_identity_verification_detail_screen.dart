import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/admin_identity_verification_model.dart';
import '../providers/admin_identity_verifications_provider.dart';

class AdminIdentityVerificationDetailScreen extends ConsumerWidget {
  final AdminIdentityVerificationModel verification;

  const AdminIdentityVerificationDetailScreen({
    super.key,
    required this.verification,
  });

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Setujui Verifikasi?',
      message:
          'Jika disetujui, customer dapat melanjutkan proses pembayaran.',
      confirmText: 'Setujui',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminIdentityVerificationsControllerProvider.notifier)
        .approve(verification.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi KTP berhasil disetujui.')),
      );

      Navigator.pop(context, true);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await _showRejectDialog(context);

    if (reason == null) return;

    final success = await ref
        .read(adminIdentityVerificationsControllerProvider.notifier)
        .reject(
          id: verification.id,
          reason: reason,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi KTP berhasil ditolak.')),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminIdentityVerificationsControllerProvider).value;
    final isUpdating = state?.updatingId == verification.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail KTP'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
        children: [
          _PhotoSection(photoPath: verification.photoPath),
          const SizedBox(height: 18),
          _InfoSection(verification: verification),
          const SizedBox(height: 18),
          _LocationSection(verification: verification),
          if (state?.errorMessage != null) ...[
            const SizedBox(height: 18),
            _MessageBox(message: state!.errorMessage!),
          ],
        ],
      ),
      bottomNavigationBar: verification.isPending
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
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
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: isUpdating
                              ? null
                              : () => _reject(context, ref),
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
                        text: isUpdating ? 'Memproses...' : 'Setujui',
                        icon: Icons.check_rounded,
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        isLoading: isUpdating,
                        onPressed:
                            isUpdating ? null : () => _approve(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(18),
                color: AppColors.white,
                child: Text(
                  verification.isApproved
                      ? 'Verifikasi ini sudah disetujui.'
                      : verification.isRejected
                          ? 'Verifikasi ini sudah ditolak.'
                          : 'Verifikasi sudah diproses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: verification.isApproved
                        ? AppColors.success
                        : verification.isRejected
                            ? AppColors.danger
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tolak Verifikasi'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Alasan penolakan, contoh: foto KTP tidak jelas',
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
  }
}

class _PhotoSection extends ConsumerWidget {
  final String photoPath;

  const _PhotoSection({
    required this.photoPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(adminIdentityDocumentUrlProvider(photoPath));

    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => const Center(
          child: Text(
            'Gagal memuat foto KTP',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        data: (url) {
          if (url.isEmpty) {
            return const Center(
              child: Text(
                'Foto KTP tidak tersedia',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Gagal menampilkan foto KTP',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
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
  final AdminIdentityVerificationModel verification;

  const _InfoSection({
    required this.verification,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Data Identitas',
      child: Column(
        children: [
          _InfoRow(label: 'Status', value: verification.status),
          _InfoRow(label: 'Booking', value: verification.bookingCode),
          _InfoRow(label: 'Customer', value: verification.customerName),
          _InfoRow(label: 'Email', value: verification.customerEmail),
          _InfoRow(label: 'Nama KTP', value: verification.ktpName),
          _InfoRow(label: 'Nomor KTP', value: verification.ktpNumberMasked),
          if (verification.adminNote != null &&
              verification.adminNote!.trim().isNotEmpty)
            _InfoRow(label: 'Catatan Admin', value: verification.adminNote!),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final AdminIdentityVerificationModel verification;

  const _LocationSection({
    required this.verification,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Lokasi Pengambilan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verification.addressText.isEmpty
                ? 'Alamat tidak tersedia'
                : verification.addressText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Lat: ${verification.latitude}\nLong: ${verification.longitude}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.5,
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

  const _SectionCard({
    required this.title,
    required this.child,
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
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