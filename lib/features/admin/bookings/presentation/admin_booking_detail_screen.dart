import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../data/models/admin_booking_model.dart';
import '../../bookings/providers/admin_bookings_provider.dart';
import '../../../../../data/models/admin_identity_verification_model.dart';
import '../../verifications/providers/admin_identity_verifications_provider.dart';

class AdminBookingDetailScreen extends ConsumerWidget {
  final AdminBookingModel booking;

  const AdminBookingDetailScreen({super.key, required this.booking});

  Future<void> _approveIdentity(
    BuildContext context,
    WidgetRef ref,
    AdminIdentityVerificationModel verification,
  ) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Setujui KTP?',
      message:
          'Jika KTP disetujui, customer dapat melanjutkan proses verifikasi kondisi barang.',
      confirmText: 'Setujui KTP',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminIdentityVerificationsControllerProvider.notifier)
        .approve(verification.id);

    if (!context.mounted) return;

    if (success) {
      ref.invalidate(adminIdentityVerificationByBookingProvider(booking.id));
      ref.invalidate(adminIdentityVerificationsControllerProvider);
      ref.invalidate(adminBookingsControllerProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi KTP berhasil disetujui.')),
      );
    }
  }

  Future<void> _rejectIdentity(
    BuildContext context,
    WidgetRef ref,
    AdminIdentityVerificationModel verification,
  ) async {
    final reason = await _showRejectDialog(context);

    if (reason == null || reason.trim().isEmpty) return;

    final success = await ref
        .read(adminIdentityVerificationsControllerProvider.notifier)
        .reject(id: verification.id, reason: reason);

    if (!context.mounted) return;

    if (success) {
      ref.invalidate(adminIdentityVerificationByBookingProvider(booking.id));
      ref.invalidate(adminIdentityVerificationsControllerProvider);
      ref.invalidate(adminBookingsControllerProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi KTP berhasil ditolak.')),
      );
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Setujui Pesanan?',
      message:
          'Pesanan akan disetujui dan customer dapat melanjutkan proses penyewaan.',
      confirmText: 'Setujui',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .approve(booking.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil disetujui.')),
      );

      Navigator.pop(context, true);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await _showRejectDialog(context);

    if (reason == null || reason.trim().isEmpty) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .reject(id: booking.id, reason: reason);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil ditolak.')),
      );

      Navigator.pop(context, true);
    }
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Mulai Sewa?',
      message:
          'Pastikan verifikasi kondisi awal barang sudah sesuai. Setelah dilanjutkan, status sewa akan menjadi berlangsung.',
      confirmText: 'Mulai Sewa',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .start(booking.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sewa berhasil dimulai.')));

      Navigator.pop(context, true);
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Selesaikan Sewa?',
      message:
          'Pastikan barang sudah dikembalikan dengan baik sebelum menyelesaikan pesanan.',
      confirmText: 'Selesaikan',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .complete(booking.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sewa berhasil diselesaikan.')),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminBookingsControllerProvider).value;
    final isUpdating = state?.updatingId == booking.id;
    final identityVerificationState = ref.watch(
      adminIdentityVerificationByBookingProvider(booking.id),
    );

    final identityVerification = identityVerificationState.asData?.value;

    final identityListState = ref.watch(
      adminIdentityVerificationsControllerProvider,
    );

    final identityUpdatingId = identityListState.asData?.value.updatingId;

    final isIdentityLoading = identityVerificationState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    final isIdentityUpdating =
        identityVerification != null &&
        identityUpdatingId == identityVerification.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Sewa'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 132),
        children: [
          _BookingSummaryCard(booking: booking),
          const SizedBox(height: 16),
          _IdentityVerificationCard(
            booking: booking,
            verificationState: identityVerificationState,
          ),
          const SizedBox(height: 16),
          _ConditionVerificationCard(booking: booking),
          if (state?.errorMessage != null) ...[
            const SizedBox(height: 16),
            _MessageBox(message: state!.errorMessage!),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: const Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: _ActionButtons(
            booking: booking,
            identityVerification: identityVerification,
            isUpdating: isUpdating || isIdentityUpdating,
            isIdentityLoading: isIdentityLoading,
            onApproveIdentity: identityVerification == null
                ? null
                : () => _approveIdentity(context, ref, identityVerification),
            onRejectIdentity: identityVerification == null
                ? null
                : () => _rejectIdentity(context, ref, identityVerification),
            onApprove: () => _approve(context, ref),
            onReject: () => _reject(context, ref),
            onStart: () => _start(context, ref),
            onComplete: () => _complete(context, ref),
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
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
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
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Tolak Pesanan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tulis alasan penolakan',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
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

class _BookingSummaryCard extends StatelessWidget {
  final AdminBookingModel booking;

  const _BookingSummaryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _CustomerAvatar(name: booking.customerName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName.trim().isEmpty
                          ? 'Customer'
                          : booking.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${booking.code}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: const [
              Icon(
                Icons.inventory_2_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'ITEM DISEWA',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BookingItemsList(booking: booking),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Tanggal Sewa',
                  value: _dateRangeText(
                    booking.rentalStartDate,
                    booking.rentalEndDate,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryValue(
                  label: 'Total Harga',
                  value: CurrencyFormatter.rupiah(booking.totalAmount),
                  alignRight: true,
                ),
              ),
            ],
          ),
          if (booking.paymentStatus != null ||
              (booking.customerNote != null &&
                  booking.customerNote!.trim().isNotEmpty)) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            if (booking.paymentStatus != null)
              _SmallInfoLine(
                icon: Icons.payments_rounded,
                label: 'Pembayaran',
                value: booking.paymentStatus!,
              ),
            if (booking.customerNote != null &&
                booking.customerNote!.trim().isNotEmpty)
              _SmallInfoLine(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                value: booking.customerNote!,
              ),
          ],
        ],
      ),
    );
  }

  String _dateRangeText(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '-';

    return '${start.day} ${_monthName(start.month)} - ${end.day} ${_monthName(end.month)} ${end.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    if (month < 1 || month > 12) return '';

    return months[month];
  }
}

class _BookingItemsList extends StatelessWidget {
  final AdminBookingModel booking;

  const _BookingItemsList({required this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking.items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.input,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Data barang belum tersedia.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      children: booking.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '1x',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _IdentityVerificationCard extends StatelessWidget {
  final AdminBookingModel booking;
  final AsyncValue<AdminIdentityVerificationModel?> verificationState;

  const _IdentityVerificationCard({
    required this.booking,
    required this.verificationState,
  });

  @override
  Widget build(BuildContext context) {
    return verificationState.when(
      loading: () {
        return _VerificationCard(
          title: 'Verifikasi KTP',
          status: _VerificationViewStatus.pending,
          icon: Icons.badge_rounded,
          child: const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return _VerificationCard(
          title: 'Verifikasi KTP',
          status: _VerificationViewStatus.rejected,
          icon: Icons.badge_rounded,
          child: _VerificationInfoBox(
            icon: Icons.error_outline_rounded,
            title: 'Gagal Memuat Data KTP',
            subtitle: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      },
      data: (verification) {
        if (verification == null) {
          return _VerificationCard(
            title: 'Verifikasi KTP',
            status: _VerificationViewStatus.pending,
            icon: Icons.badge_rounded,
            child: const _VerificationInfoBox(
              icon: Icons.hourglass_top_rounded,
              title: 'Menunggu Verifikasi KTP',
              subtitle:
                  'Customer belum mengirim data KTP atau data belum terbaca pada sistem admin.',
            ),
          );
        }

        final status = _identityStatus(verification);

        return _VerificationCard(
          title: 'Verifikasi KTP',
          status: status,
          icon: Icons.badge_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IdentityPhotoPreview(photoPath: verification.photoPath),
              const SizedBox(height: 12),
              _VerificationInfoBox(
                icon: Icons.person_rounded,
                title: 'Data KTP',
                subtitle:
                    'Nama KTP: ${_emptyDash(verification.ktpName)}\nNomor KTP: ${_emptyDash(verification.ktpNumberMasked)}\nStatus: ${verification.status}',
              ),
              const SizedBox(height: 12),
              _VerificationInfoBox(
                icon: Icons.location_on_outlined,
                title: 'Lokasi Verifikasi',
                subtitle:
                    '${_emptyDash(verification.addressText)}\nLat: ${verification.latitude}\nLong: ${verification.longitude}',
              ),
            ],
          ),
        );
      },
    );
  }

  _VerificationViewStatus _identityStatus(
    AdminIdentityVerificationModel verification,
  ) {
    if (verification.isApproved) {
      return _VerificationViewStatus.approved;
    }

    if (verification.isRejected) {
      return _VerificationViewStatus.rejected;
    }

    return _VerificationViewStatus.pending;
  }

  static String _emptyDash(String value) {
    return value.trim().isEmpty ? '-' : value;
  }
}

class _IdentityPhotoPreview extends ConsumerWidget {
  final String photoPath;

  const _IdentityPhotoPreview({required this.photoPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(adminIdentityDocumentUrlProvider(photoPath));

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(14),
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        data: (url) {
          if (url.trim().isEmpty) {
            return const Center(
              child: Text(
                'Foto KTP tidak tersedia',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w800,
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

class _ConditionVerificationCard extends StatelessWidget {
  final AdminBookingModel booking;

  const _ConditionVerificationCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final status = _conditionStatus(booking);

    return _VerificationCard(
      title: 'Verifikasi Kondisi Barang',
      status: status,
      icon: Icons.verified_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConditionPreview(status: status),
          const SizedBox(height: 12),
          _VerificationInfoBox(
            icon: Icons.info_outline_rounded,
            title: 'Status Kondisi Awal',
            subtitle: _conditionMessage(booking.status),
          ),
        ],
      ),
    );
  }

  _VerificationViewStatus _conditionStatus(AdminBookingModel booking) {
    if (booking.status == 'rejected' ||
        booking.status == 'cancelled' ||
        booking.status == 'expired') {
      return _VerificationViewStatus.rejected;
    }

    if (booking.status == 'ongoing' || booking.status == 'completed') {
      return _VerificationViewStatus.approved;
    }

    if (booking.canStart) {
      return _VerificationViewStatus.pending;
    }

    return _VerificationViewStatus.pending;
  }

  String _conditionMessage(String status) {
    switch (status) {
      case 'pending_verification':
        return 'Verifikasi kondisi belum dapat diproses sebelum KTP disetujui.';
      case 'waiting_payment':
        return 'Menunggu customer melakukan pembayaran terlebih dahulu.';
      case 'payment_pending':
      case 'paid':
      case 'approved':
        return 'Menunggu atau memproses verifikasi kondisi awal barang. Jika data sudah sesuai, tekan Mulai Sewa.';
      case 'ongoing':
        return 'Kondisi awal sudah disetujui dan masa sewa sedang berlangsung.';
      case 'completed':
        return 'Sewa sudah selesai.';
      case 'rejected':
        return 'Pesanan sudah ditolak.';
      case 'cancelled':
        return 'Pesanan sudah dibatalkan.';
      case 'expired':
        return 'Pesanan sudah kedaluwarsa.';
      default:
        return 'Status kondisi mengikuti proses booking saat ini.';
    }
  }
}

enum _VerificationViewStatus { pending, approved, rejected }

class _VerificationCard extends StatelessWidget {
  final String title;
  final _VerificationViewStatus status;
  final IconData icon;
  final Widget child;

  const _VerificationCard({
    required this.title,
    required this.status,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _VerificationStatusIcon(status: status),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Color _statusColor(_VerificationViewStatus status) {
    switch (status) {
      case _VerificationViewStatus.pending:
        return AppColors.warning;
      case _VerificationViewStatus.approved:
        return AppColors.success;
      case _VerificationViewStatus.rejected:
        return AppColors.danger;
    }
  }
}

class _KtpLine extends StatelessWidget {
  final double width;

  const _KtpLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 9,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _ConditionPreview extends StatelessWidget {
  final _VerificationViewStatus status;

  const _ConditionPreview({required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status == _VerificationViewStatus.approved;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApproved
            ? AppColors.success.withOpacity(0.08)
            : AppColors.input,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApproved
              ? AppColors.success.withOpacity(0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isApproved
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: isApproved ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isApproved
                  ? 'Kondisi awal sudah disetujui.'
                  : 'Menunggu verifikasi kondisi awal barang.',
              style: TextStyle(
                color: isApproved ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _VerificationInfoBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStatusIcon extends StatelessWidget {
  final _VerificationViewStatus status;

  const _VerificationStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _VerificationViewStatus.pending:
        return const Icon(
          Icons.hourglass_top_rounded,
          color: AppColors.warning,
          size: 22,
        );
      case _VerificationViewStatus.approved:
        return const Icon(
          Icons.verified_rounded,
          color: AppColors.success,
          size: 22,
        );
      case _VerificationViewStatus.rejected:
        return const Icon(
          Icons.cancel_rounded,
          color: AppColors.danger,
          size: 22,
        );
    }
  }
}

class _ActionButtons extends StatelessWidget {
  final AdminBookingModel booking;
  final AdminIdentityVerificationModel? identityVerification;
  final bool isUpdating;
  final bool isIdentityLoading;
  final VoidCallback? onApproveIdentity;
  final VoidCallback? onRejectIdentity;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _ActionButtons({
    required this.booking,
    required this.identityVerification,
    required this.isUpdating,
    required this.isIdentityLoading,
    required this.onApproveIdentity,
    required this.onRejectIdentity,
    required this.onApprove,
    required this.onReject,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (booking.status == 'pending_verification') {
      if (isIdentityLoading) {
        return const SizedBox(
          height: 56,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final verification = identityVerification;

      if (verification == null) {
        return const Text(
          'Menunggu customer mengirim atau melengkapi verifikasi KTP.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w900,
            height: 1.4,
          ),
        );
      }

      if (verification.isPending) {
        return Row(
          children: [
            Expanded(
              child: _RejectButton(
                text: 'Tolak KTP',
                onPressed: onRejectIdentity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Setujui',
                icon: Icons.verified_rounded,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                onPressed: onApproveIdentity,
              ),
            ),
          ],
        );
      }

      if (verification.isApproved) {
        return const Text(
          'KTP sudah disetujui. Menunggu customer mengirim verifikasi kondisi awal barang.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.w900,
            height: 1.4,
          ),
        );
      }

      if (verification.isRejected) {
        return const Text(
          'KTP ditolak. Menunggu customer mengirim ulang verifikasi KTP.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w900,
            height: 1.4,
          ),
        );
      }
    }

    if (booking.canStart) {
      return AppButton(
        text: 'Mulai Sewa',
        icon: Icons.play_arrow_rounded,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        onPressed: onStart,
      );
    }

    if (booking.canComplete) {
      return AppButton(
        text: 'Selesaikan Sewa',
        icon: Icons.task_alt_rounded,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        onPressed: onComplete,
      );
    }

    if (booking.canApprove) {
      return Row(
        children: [
          Expanded(
            child: _RejectButton(text: 'Tolak Pesanan', onPressed: onReject),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: 'Setujui Pesanan',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.black,
              onPressed: onApprove,
            ),
          ),
        ],
      );
    }

    return Text(
      _message(booking.status),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  String _message(String status) {
    switch (status) {
      case 'waiting_payment':
        return 'Menunggu customer melakukan pembayaran.';
      case 'payment_pending':
        return 'Menunggu status pembayaran diperbarui.';
      case 'paid':
        return 'Pembayaran berhasil. Menunggu customer mengirim verifikasi kondisi awal barang.';
      case 'approved':
        return 'Menunggu customer mengirim verifikasi kondisi awal barang.';
      case 'ongoing':
        return 'Masa sewa sedang berlangsung.';
      case 'completed':
        return 'Sewa sudah selesai.';
      case 'rejected':
        return 'Pesanan sudah ditolak.';
      case 'cancelled':
        return 'Pesanan sudah dibatalkan.';
      case 'expired':
        return 'Pesanan sudah kedaluwarsa.';
      default:
        return 'Tidak ada aksi untuk status sewa ini.';
    }
  }
}

class _RejectButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _RejectButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _label(status);
    final color = _color(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _label(String status) {
    switch (status) {
      case 'pending_verification':
        return 'MENUNGGU';
      case 'waiting_payment':
        return 'MENUNGGU BAYAR';
      case 'payment_pending':
        return 'PROSES BAYAR';
      case 'paid':
        return 'TERBAYAR';
      case 'approved':
        return 'DISETUJUI';
      case 'ongoing':
        return 'BERLANGSUNG';
      case 'completed':
        return 'SELESAI';
      case 'rejected':
        return 'DITOLAK';
      case 'cancelled':
        return 'DIBATALKAN';
      case 'expired':
        return 'KEDALUWARSA';
      default:
        return status.toUpperCase();
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'pending_verification':
      case 'waiting_payment':
      case 'payment_pending':
      case 'approved':
        return AppColors.warning;
      case 'paid':
      case 'ongoing':
      case 'completed':
        return AppColors.success;
      case 'rejected':
      case 'cancelled':
      case 'expired':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _CustomerAvatar extends StatelessWidget {
  final String name;

  const _CustomerAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _SummaryValue({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SmallInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SmallInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
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
              displayValue,
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
