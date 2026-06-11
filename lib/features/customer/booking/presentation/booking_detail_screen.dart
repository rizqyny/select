import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/models/payment_model.dart';
import 'payment_webview_screen.dart';
import '../providers/booking_detail_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  String _bottomStatusMessage(String status) {
    switch (status) {
      case 'pending_verification':
        return 'Silakan verifikasi KTP terlebih dahulu.';
      case 'rejected':
        return 'Booking ditolak oleh admin.';
      case 'cancelled':
        return 'Booking sudah dibatalkan.';
      case 'expired':
        return 'Booking sudah kedaluwarsa.';
      case 'approved':
        return 'Booking sudah disetujui admin.';
      case 'ongoing':
        return 'Masa sewa sedang berlangsung.';
      case 'completed':
        return 'Booking sudah selesai.';
      default:
        return 'Booking belum berada pada status menunggu pembayaran.';
    }
  }

  bool _needsBeforeConditionVerification(BookingModel booking) {
    return booking.status == 'payment_pending' ||
        booking.status == 'paid' ||
        booking.status == 'waiting_admin_approval';
  }

  Future<void> _createOrOpenPayment(
    BuildContext context,
    WidgetRef ref,
    BookingDetailState state,
  ) async {
    if (!state.booking.canPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pembayaran baru bisa dilakukan setelah verifikasi KTP disetujui admin.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    PaymentModel? payment = state.payment;

    if (payment == null || payment.redirectUrl == null) {
      payment = await ref
          .read(bookingDetailControllerProvider(bookingId).notifier)
          .createPayment();
    }

    if (!context.mounted || payment == null) return;

    final redirectUrl = payment.redirectUrl;

    if (redirectUrl == null || redirectUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL pembayaran tidak ditemukan.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final result = await context.push<bool>(
      '/customer/payment-webview',
      extra: PaymentWebViewArgs(redirectUrl: redirectUrl, title: 'Pembayaran'),
    );

    if (!context.mounted) return;

    if (result == true) {
      await ref
          .read(bookingDetailControllerProvider(bookingId).notifier)
          .refresh();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pembayaran diperbarui.')),
      );
    }
  }

  int _firstItemId(BookingModel booking) {
    if (booking.items.isEmpty) return 0;

    return booking.items.first.itemId;
  }

  Future<void> _openConditionVerification(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
    String type,
  ) async {
    final itemId = _firstItemId(booking);

    if (itemId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data item booking tidak ditemukan.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final result = await context.push<bool>(
      '/customer/verifications/condition/${booking.id}/$itemId/$type',
    );

    if (result == true && context.mounted) {
      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .markConditionVerificationSubmitted(type);

      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(bookingDetailControllerProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: detailState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: readableError(error),
          onRetry: () {
            ref
                .read(bookingDetailControllerProvider(bookingId).notifier)
                .refresh();
          },
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () {
              return ref
                  .read(bookingDetailControllerProvider(bookingId).notifier)
                  .refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
              children: [
                _BookingInfoCard(booking: state.booking),
                const SizedBox(height: 18),
                _ItemsSection(booking: state.booking),
                const SizedBox(height: 18),
                _PaymentSection(booking: state.booking, payment: state.payment),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 18),
                  _MessageBox(message: state.errorMessage!),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: detailState.maybeWhen(
        data: (state) {
          final booking = state.booking;
          final payment = state.payment;
          final alreadyPaid =
              payment?.isPaid == true || booking.status == 'paid';

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: alreadyPaid
                  ? const Text(
                      'Pembayaran sudah selesai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : booking.needsIdentityVerification
                  ? state.hasSubmittedIdentityVerification
                        ? const Text(
                            'Verifikasi KTP sudah dikirim. Menunggu persetujuan admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : AppButton(
                            text: 'Verifikasi KTP Dulu',
                            icon: Icons.badge_rounded,
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.black,
                            onPressed: () async {
                              final result = await context.push<bool>(
                                '/customer/verifications/identity/${booking.id}',
                              );

                              if (result == true && context.mounted) {
                                await ref
                                    .read(
                                      bookingDetailControllerProvider(
                                        booking.id,
                                      ).notifier,
                                    )
                                    .markIdentityVerificationSubmitted();
                              }
                            },
                          )
                  : booking.canPay
                  ? AppButton(
                      text: state.isCreatingPayment
                          ? 'Membuat Pembayaran...'
                          : 'Bayar Sekarang',
                      icon: Icons.payment_rounded,
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      isLoading: state.isCreatingPayment,
                      onPressed: state.isCreatingPayment
                          ? null
                          : () => _createOrOpenPayment(context, ref, state),
                    )
                  : _needsBeforeConditionVerification(booking)
                  ? state.hasSubmittedBeforeConditionVerification
                        ? const Text(
                            'Verifikasi kondisi awal barang sudah dikirim. Menunggu persetujuan admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w900,
                              height: 1.4,
                            ),
                          )
                        : AppButton(
                            text: 'Verifikasi Kondisi Awal Barang',
                            icon: Icons.fact_check_rounded,
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.white,
                            onPressed: () {
                              _openConditionVerification(
                                context,
                                ref,
                                booking,
                                'before_rent',
                              );
                            },
                          )
                  : booking.status == 'approved'
                  ? const Text(
                      'Booking sudah disetujui. Silakan lanjutkan proses pengambilan barang sesuai arahan admin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                      ),
                    )
                  : booking.status == 'ongoing' || booking.status == 'active'
                  ? const Text(
                      'Masa sewa sedang berjalan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                      ),
                    )
                  : Text(
                      _bottomStatusMessage(booking.status),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _BookingInfoCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingInfoCard({required this.booking});

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
          _StatusBadge(status: booking.status),
          const SizedBox(height: 14),
          Text(
            booking.code,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Tanggal Sewa',
            value: _dateRangeText(
              booking.rentalStartDate,
              booking.rentalEndDate,
            ),
          ),
          _InfoRow(
            label: 'Total',
            value: CurrencyFormatter.rupiah(booking.totalAmount),
          ),
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

class _ItemsSection extends StatelessWidget {
  final BookingModel booking;

  const _ItemsSection({required this.booking});

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

class _PaymentSection extends StatelessWidget {
  final BookingModel booking;
  final PaymentModel? payment;

  const _PaymentSection({required this.booking, required this.payment});

  @override
  Widget build(BuildContext context) {
    final currentPayment = payment;

    String emptyMessage;

    if (booking.needsIdentityVerification) {
      emptyMessage =
          'Pembayaran belum tersedia. Customer harus melakukan verifikasi KTP dan menunggu persetujuan admin.';
    } else if (booking.canPay) {
      emptyMessage =
          'Pembayaran belum dibuat. Tekan tombol Bayar Sekarang untuk membuat pembayaran.';
    } else {
      emptyMessage = 'Pembayaran belum tersedia untuk status booking ini.';
    }

    return _SectionCard(
      title: 'Pembayaran',
      child: currentPayment == null
          ? Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            )
          : Column(
              children: [
                _InfoRow(label: 'Provider', value: currentPayment.provider),
                _InfoRow(
                  label: 'Order ID',
                  value: currentPayment.externalOrderId,
                ),
                _InfoRow(label: 'Status', value: currentPayment.status),
                _InfoRow(
                  label: 'Jumlah',
                  value: CurrencyFormatter.rupiah(currentPayment.grossAmount),
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

  const _InfoRow({required this.label, required this.value});

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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'approved':
      case 'ongoing':
      case 'completed':
        return AppColors.success;
      case 'rejected':
      case 'cancelled':
      case 'expired':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_verification':
        return 'Menunggu Verifikasi';
      case 'waiting_payment':
        return 'Menunggu Pembayaran';
      case 'payment_pending':
        return 'Payment Pending';
      case 'paid':
        return 'Paid';
      case 'approved':
        return 'Approved';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Batal';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 14),
              const Text(
                'Gagal memuat detail pesanan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
