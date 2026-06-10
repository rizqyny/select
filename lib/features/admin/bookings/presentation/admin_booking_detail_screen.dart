import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../data/models/admin_booking_model.dart';
import '../../bookings/providers/admin_bookings_provider.dart';

class AdminBookingDetailScreen extends ConsumerWidget {
  final AdminBookingModel booking;

  const AdminBookingDetailScreen({
    super.key,
    required this.booking,
  });

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Approve Booking?',
      message: 'Booking akan disetujui dan siap diproses peminjamannya.',
      confirmText: 'Approve',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .approve(booking.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil disetujui.')),
      );

      Navigator.pop(context, true);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await _showRejectDialog(context);

    if (reason == null) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .reject(
          id: booking.id,
          reason: reason,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil ditolak.')),
      );

      Navigator.pop(context, true);
    }
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Mulai Sewa?',
      message: 'Status booking akan diubah menjadi sedang berlangsung.',
      confirmText: 'Mulai',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .start(booking.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil dimulai.')),
      );

      Navigator.pop(context, true);
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Selesaikan Booking?',
      message: 'Pastikan barang sudah dikembalikan dengan baik.',
      confirmText: 'Selesaikan',
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminBookingsControllerProvider.notifier)
        .complete(booking.id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil diselesaikan.')),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminBookingsControllerProvider).value;
    final isUpdating = state?.updatingId == booking.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
        children: [
          _BookingInfoCard(booking: booking),
          const SizedBox(height: 18),
          _CustomerInfoCard(booking: booking),
          const SizedBox(height: 18),
          _ItemsSection(booking: booking),
          if (state?.errorMessage != null) ...[
            const SizedBox(height: 18),
            _MessageBox(message: state!.errorMessage!),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: _ActionButtons(
            booking: booking,
            isUpdating: isUpdating,
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
          title: const Text('Tolak Booking'),
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
  }
}

class _BookingInfoCard extends StatelessWidget {
  final AdminBookingModel booking;

  const _BookingInfoCard({
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Informasi Booking',
      child: Column(
        children: [
          _InfoRow(label: 'Kode', value: booking.code),
          _InfoRow(label: 'Status', value: booking.status),
          _InfoRow(
            label: 'Tanggal',
            value: _dateRangeText(
              booking.rentalStartDate,
              booking.rentalEndDate,
            ),
          ),
          _InfoRow(
            label: 'Total',
            value: CurrencyFormatter.rupiah(booking.totalAmount),
          ),
          if (booking.paymentStatus != null)
            _InfoRow(label: 'Payment', value: booking.paymentStatus!),
          if (booking.customerNote != null &&
              booking.customerNote!.trim().isNotEmpty)
            _InfoRow(label: 'Catatan', value: booking.customerNote!),
        ],
      ),
    );
  }

  String _dateRangeText(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '-';

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final AdminBookingModel booking;

  const _CustomerInfoCard({
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Data Customer',
      child: Column(
        children: [
          _InfoRow(label: 'Nama', value: booking.customerName),
          _InfoRow(label: 'Email', value: booking.customerEmail),
          _InfoRow(label: 'Telepon', value: booking.customerPhone),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final AdminBookingModel booking;

  const _ItemsSection({
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final items = booking.items;

    return _SectionCard(
      title: 'Barang Disewa',
      child: items.isEmpty
          ? const Text(
              'Data barang belum tersedia.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: items.map((item) {
                final displayDailyPrice = item.dailyPrice > 0
                    ? item.dailyPrice
                    : booking.fallbackDailyPricePerItem;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.devices_other_rounded,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.dailyPrice(displayDailyPrice),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AdminBookingModel booking;
  final bool isUpdating;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _ActionButtons({
    required this.booking,
    required this.isUpdating,
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

    if (booking.canApprove) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onReject,
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
              text: 'Approve',
              icon: Icons.check_rounded,
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              onPressed: onApprove,
            ),
          ),
        ],
      );
    }

    if (booking.canStart) {
      return AppButton(
        text: 'Mulai Sewa',
        icon: Icons.play_arrow_rounded,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        onPressed: onStart,
      );
    }

    if (booking.canComplete) {
      return AppButton(
        text: 'Selesaikan Booking',
        icon: Icons.task_alt_rounded,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        onPressed: onComplete,
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
      case 'pending_verification':
        return 'Menunggu verifikasi KTP customer.';
      case 'waiting_payment':
        return 'Menunggu customer melakukan pembayaran.';
      case 'payment_pending':
        return 'Menunggu status pembayaran diperbarui.';
      case 'completed':
        return 'Booking sudah selesai.';
      case 'rejected':
        return 'Booking sudah ditolak.';
      case 'cancelled':
        return 'Booking sudah dibatalkan.';
      case 'expired':
        return 'Booking sudah kedaluwarsa.';
      default:
        return 'Tidak ada aksi untuk status booking ini.';
    }
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
    final displayValue = value.trim().isEmpty ? '-' : value;

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