import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../data/models/booking_model.dart';
import '../providers/customer_bookings_provider.dart';

class CustomerBookingsScreen extends ConsumerWidget {
  const CustomerBookingsScreen({super.key});

  static const _filters = <_BookingFilter>[
    _BookingFilter(label: 'Semua', value: null),
    _BookingFilter(label: 'Pending', value: 'pending_verification'),
    _BookingFilter(label: 'Bayar', value: 'waiting_payment'),
    _BookingFilter(label: 'Paid', value: 'paid'),
    _BookingFilter(label: 'Approved', value: 'approved'),
    _BookingFilter(label: 'Ongoing', value: 'ongoing'),
    _BookingFilter(label: 'Selesai', value: 'completed'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(customerBookingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: bookingsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: readableError(error),
          onRetry: () {
            ref.read(customerBookingsControllerProvider.notifier).refresh();
          },
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () {
              return ref
                  .read(customerBookingsControllerProvider.notifier)
                  .refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = state.selectedStatus == filter.value;

                      return ChoiceChip(
                        label: Text(filter.label),
                        selected: selected,
                        onSelected: (_) {
                          ref
                              .read(customerBookingsControllerProvider.notifier)
                              .setStatus(filter.value);
                        },
                        selectedColor: AppColors.black,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        backgroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.border),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (state.bookings.isEmpty)
                  const _EmptyState()
                else
                  ...state.bookings.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BookingCard(
                        booking: booking,
                        onTap: () {
                          context.push('/customer/bookings/${booking.id}');
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateText = _dateRangeText(
      booking.rentalStartDate,
      booking.rentalEndDate,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dateText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.rupiah(booking.totalAmount),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${booking.items.length} item disewa',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateRangeText(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Tanggal sewa belum tersedia';

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'approved':
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
        return 'Pending';
      case 'waiting_payment':
        return 'Bayar';
      case 'payment_pending':
        return 'Payment';
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

class _BookingFilter {
  final String label;
  final String? value;

  const _BookingFilter({required this.label, required this.value});
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textSecondary,
            size: 54,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada pesanan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pesanan yang kamu buat akan muncul di halaman ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
