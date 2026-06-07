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

  Future<void> _createOrOpenPayment(
    BuildContext context,
    WidgetRef ref,
    BookingDetailState state,
  ) async {
    PaymentModel? payment = state.payment;

    if (payment == null || payment.redirectUrl == null) {
      payment = await ref
          .read(bookingDetailControllerProvider(bookingId).notifier)
          .createPayment();
    }

    if (!context.mounted || payment == null) return;

    final redirectUrl = payment.redirectUrl;

    if (redirectUrl == null || redirectUrl.isEmpty) {
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
      ref.read(bookingDetailControllerProvider(bookingId).notifier).refresh();
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
                _ItemsSection(items: state.booking.items),
                const SizedBox(height: 18),
                _PaymentSection(payment: state.payment),
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
          final payment = state.payment;
          final alreadyPaid =
              payment?.isPaid == true || state.booking.status == 'paid';

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
                  : AppButton(
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
  final List<BookingItemSummary> items;

  const _ItemsSection({required this.items});

  @override
  Widget build(BuildContext context) {
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
                        CurrencyFormatter.dailyPrice(item.dailyPrice),
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
  final PaymentModel? payment;

  const _PaymentSection({required this.payment});

  @override
  Widget build(BuildContext context) {
    final currentPayment = payment;

    return _SectionCard(
      title: 'Pembayaran',
      child: currentPayment == null
          ? const Text(
              'Pembayaran belum dibuat.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
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
              value,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.warning,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, textAlign: TextAlign.center));
  }
}
