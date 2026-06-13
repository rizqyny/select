import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../data/models/booking_model.dart';
import '../providers/customer_bookings_provider.dart';

class CustomerBookingsScreen extends ConsumerStatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  ConsumerState<CustomerBookingsScreen> createState() =>
      _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState
    extends ConsumerState<CustomerBookingsScreen> {
  int _selectedTabIndex = 0;

  static const _tabs = <_BookingTab>[
    _BookingTab(
      label: 'Menunggu',
      statuses: [
        'pending_verification',
        'waiting_payment',
        'payment_pending',
        'paid',
      ],
    ),
    _BookingTab(
      label: 'Diproses',
      statuses: ['approved', 'waiting_admin_approval'],
    ),
    _BookingTab(label: 'Berlangsung', statuses: ['ongoing', 'active']),
    _BookingTab(
      label: 'Selesai',
      statuses: ['completed', 'rejected', 'cancelled', 'expired'],
    ),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(customerBookingsControllerProvider.notifier).setStatus(null);
    });
  }

  List<BookingModel> _filteredBookings(List<BookingModel> bookings) {
    final selectedTab = _tabs[_selectedTabIndex];

    return bookings.where((booking) {
      return selectedTab.statuses.contains(booking.status);
    }).toList();
  }

  Future<void> _refresh() {
    return ref.read(customerBookingsControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(customerBookingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pesanan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'refresh') {
                _refresh();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _BookingTabs(
              tabs: _tabs,
              selectedIndex: _selectedTabIndex,
              onSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ),
          Expanded(
            child: bookingsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stackTrace) =>
                  _ErrorState(message: readableError(error), onRetry: _refresh),
              data: (state) {
                final filteredBookings = _filteredBookings(state.bookings);

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                    children: [
                      if (filteredBookings.isEmpty)
                        _EmptyState(tabLabel: _tabs[_selectedTabIndex].label)
                      else
                        ...filteredBookings.map((booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _BookingCard(
                              booking: booking,
                              onTap: () {
                                context.push(
                                  '/customer/bookings/${booking.id}',
                                );
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTabs extends StatelessWidget {
  final List<_BookingTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _BookingTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 76 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
    final item = booking.items.isNotEmpty ? booking.items.first : null;
    final imageUrl = item?.imageUrl.trim() ?? '';
    final itemName = item?.itemName.trim().isNotEmpty == true
        ? item!.itemName
        : booking.code;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BookingImage(imageUrl: imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateRangeText(
                        booking.rentalStartDate,
                        booking.rentalEndDate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _StatusBadge(status: booking.status),
                        const SizedBox(width: 10),
                        Flexible(
                          flex: 2,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyFormatter.rupiah(booking.totalAmount),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dateRangeText(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Tanggal sewa belum tersedia';

    return '${start.day} - ${end.day} ${_monthName(end.month)} ${end.year}';
  }

  static String _monthName(int month) {
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

class _BookingImage extends StatelessWidget {
  final String imageUrl;

  const _BookingImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const _ImageFallback()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const _ImageFallback();
              },
            ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textSecondary,
        size: 34,
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'ongoing':
      case 'active':
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
        return 'MENUNGGU';
      case 'waiting_payment':
        return 'BAYAR';
      case 'payment_pending':
        return 'PAYMENT';
      case 'paid':
        return 'MENUNGGU';
      case 'approved':
        return 'DIPROSES';
      case 'ongoing':
      case 'active':
        return 'BERLANGSUNG';
      case 'completed':
        return 'SELESAI';
      case 'rejected':
        return 'DITOLAK';
      case 'cancelled':
        return 'BATAL';
      case 'expired':
        return 'EXPIRED';
      default:
        return status.toUpperCase();
    }
  }
}

class _BookingTab {
  final String label;
  final List<String> statuses;

  const _BookingTab({required this.label, required this.statuses});
}

class _EmptyState extends StatelessWidget {
  final String tabLabel;

  const _EmptyState({required this.tabLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textSecondary,
            size: 56,
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada pesanan $tabLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pesanan yang kamu buat akan muncul sesuai statusnya di halaman ini.',
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
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Center(
        child: Container(
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
                'Gagal memuat pesanan',
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
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
