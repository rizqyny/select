import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/admin_dashboard_model.dart';
import 'providers/admin_dashboard_provider.dart';
import '../../../data/models/admin_booking_model.dart';
import '../bookings/providers/admin_bookings_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(adminDashboardControllerProvider);
    final adminBookingsState = ref.watch(adminBookingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: dashboardState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stackTrace) => _ErrorState(
            message: readableError(error),
            onRetry: () {
              ref.read(adminDashboardControllerProvider.notifier).refresh();
            },
          ),
          data: (dashboard) {
            final adminBookings =
                adminBookingsState.asData?.value.bookings ??
                const <AdminBookingModel>[];
            return RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(adminDashboardControllerProvider.notifier)
                    .refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 110),
                children: [
                  const _DashboardHeader(),
                  const SizedBox(height: 28),
                  _SummaryGrid(
                    summary: dashboard.summary,
                    statusDistribution: dashboard.statusDistribution,
                    adminBookings: adminBookings,
                  ),
                  const SizedBox(height: 24),
                  _RecentBookingsHeader(
                    onSeeAll: () {
                      context.go('/admin/bookings');
                    },
                  ),
                  const SizedBox(height: 16),
                  _RecentBookingsSection(
                    recentBookings: dashboard.recentBookings,
                    adminBookings: adminBookings,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Halo, Admin',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final AdminDashboardSummary summary;
  final List<AdminDashboardStatusCount> statusDistribution;
  final List<AdminBookingModel> adminBookings;

  const _SummaryGrid({
    required this.summary,
    required this.statusDistribution,
    required this.adminBookings,
  });

  @override
  Widget build(BuildContext context) {
    final activeFromBookings = adminBookings.where((booking) {
      return booking.status == 'ongoing' || booking.status == 'active';
    }).length;

    final completedFromBookings = adminBookings.where((booking) {
      return booking.status == 'completed';
    }).length;

    final activeFromDistribution = _countStatuses(['ongoing', 'active']);

    final completedFromDistribution = _countStatuses(['completed']);

    final activeRentals = activeFromBookings > 0
        ? activeFromBookings
        : activeFromDistribution > 0
        ? activeFromDistribution
        : summary.activeRentals;

    final completedBookings = completedFromBookings > 0
        ? completedFromBookings
        : completedFromDistribution;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.12,
      ),
      children: [
        _SummaryCard(
          title: 'Total Barang',
          value: summary.totalItems.toString(),
          icon: Icons.inventory_2_outlined,
        ),
        _SummaryCard(
          title: 'Sewa Aktif',
          value: activeRentals.toString(),
          icon: Icons.restart_alt_rounded,
        ),
        _SummaryCard(
          title: 'Total Booking Selesai',
          value: completedBookings.toString(),
          icon: Icons.assignment_turned_in_outlined,
        ),
        _RevenueSummaryCard(
          title: 'Total Pendapatan',
          amount: summary.totalRevenue,
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }

  int _countStatuses(List<String> statuses) {
    return statusDistribution.fold<int>(0, (total, item) {
      if (statuses.contains(item.status)) {
        return total + item.count;
      }

      return total;
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallIconBox(icon: icon),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  final String title;
  final num amount;
  final IconData icon;

  const _RevenueSummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallIconBox(icon: icon),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Rp ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: _compactMoney(amount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _compactMoney(num value) {
    if (value >= 1000000000) {
      return '${_clean(value / 1000000000)} M';
    }

    if (value >= 1000000) {
      return '${_clean(value / 1000000)} jt';
    }

    if (value >= 1000) {
      return '${_clean(value / 1000)} rb';
    }

    return value.toStringAsFixed(0);
  }

  static String _clean(num value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _SmallIconBox extends StatelessWidget {
  final IconData icon;

  const _SmallIconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 22),
    );
  }
}

class _RecentBookingsHeader extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _RecentBookingsHeader({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Pesanan Terbaru',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onSeeAll,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Lihat Semua',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentBookingsSection extends StatelessWidget {
  final List<AdminDashboardRecentBooking> recentBookings;
  final List<AdminBookingModel> adminBookings;

  const _RecentBookingsSection({
    required this.recentBookings,
    required this.adminBookings,
  });

  @override
  Widget build(BuildContext context) {
    if (recentBookings.isEmpty) {
      return const _EmptyRecentBookingCard();
    }

    return Column(
      children: recentBookings.take(5).map((recentBooking) {
        final matchedBooking = _findMatchingBooking(recentBooking);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _RecentBookingCard(
            booking: recentBooking,
            matchedBooking: matchedBooking,
            onTap: () {
              if (matchedBooking == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Data detail booking belum termuat. Silakan buka dari menu Sewa.',
                    ),
                  ),
                );
                context.go('/admin/bookings');
                return;
              }

              context.push<bool>(
                '/admin/bookings/${matchedBooking.id}',
                extra: matchedBooking,
              );
            },
          ),
        );
      }).toList(),
    );
  }

  AdminBookingModel? _findMatchingBooking(AdminDashboardRecentBooking recent) {
    final recentId = _recentBookingId(recent);
    final recentCode = _recentBookingCode(recent);

    for (final booking in adminBookings) {
      if (recentId > 0 && booking.id == recentId) {
        return booking;
      }

      if (recentCode.isNotEmpty && booking.code == recentCode) {
        return booking;
      }
    }

    return null;
  }

  static int _recentBookingId(dynamic booking) {
    try {
      final value = booking.id;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    } catch (_) {}

    try {
      final value = booking.bookingId;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    } catch (_) {}

    return 0;
  }

  static String _recentBookingCode(dynamic booking) {
    try {
      final value = booking.code?.toString() ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    } catch (_) {}

    try {
      final value = booking.bookingCode?.toString() ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    } catch (_) {}

    return '';
  }
}

class _RecentBookingCard extends StatelessWidget {
  final AdminDashboardRecentBooking booking;
  final AdminBookingModel? matchedBooking;
  final VoidCallback onTap;

  const _RecentBookingCard({
    required this.booking,
    required this.matchedBooking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemName = _itemName(booking, matchedBooking);
    final customerName = _customerName(booking, matchedBooking);
    final imageUrl = _imageUrl(booking, matchedBooking);
    final dateText = _dateRangeText(booking, matchedBooking);
    final amount = _totalAmount(booking, matchedBooking);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _RecentBookingImage(imageUrl: imageUrl),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 82,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amount <= 0
                                ? '-'
                                : CurrencyFormatter.rupiah(amount),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
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

  static String _itemName(dynamic recent, AdminBookingModel? matchedBooking) {
    if (matchedBooking != null && matchedBooking.items.isNotEmpty) {
      final dynamic first = matchedBooking.items.first;

      try {
        final value = first.itemName?.toString() ?? '';
        if (value.trim().isNotEmpty) return value.trim();
      } catch (_) {}
    }

    try {
      final value = recent.itemName?.toString() ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    } catch (_) {}

    try {
      final value = recent.itemNameSnapshot?.toString() ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    } catch (_) {}

    try {
      final value = recent.code?.toString() ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    } catch (_) {}

    return 'Pesanan';
  }

  static String _customerName(
    dynamic recent,
    AdminBookingModel? matchedBooking,
  ) {
    if (matchedBooking != null &&
        matchedBooking.customerName.trim().isNotEmpty) {
      return matchedBooking.customerName.trim();
    }

    try {
      final value = recent.customerName?.toString() ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    } catch (_) {}

    return 'Customer';
  }

  static String _imageUrl(dynamic recent, AdminBookingModel? matchedBooking) {
    if (matchedBooking != null && matchedBooking.items.isNotEmpty) {
      final dynamic first = matchedBooking.items.first;

      try {
        final value = first.imageUrl?.toString() ?? '';
        if (value.trim().isNotEmpty && !value.contains('example.com')) {
          return value.trim();
        }
      } catch (_) {}

      try {
        final value = first.item?.primaryImage?.publicUrl?.toString() ?? '';
        if (value.trim().isNotEmpty && !value.contains('example.com')) {
          return value.trim();
        }
      } catch (_) {}
    }

    try {
      final value = recent.imageUrl?.toString() ?? '';
      if (value.trim().isNotEmpty && !value.contains('example.com')) {
        return value.trim();
      }
    } catch (_) {}

    return '';
  }

  static num _totalAmount(dynamic recent, AdminBookingModel? matchedBooking) {
    if (matchedBooking != null) {
      return matchedBooking.totalAmount;
    }

    try {
      final value = recent.totalAmount;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
    } catch (_) {}

    return 0;
  }

  static String _dateRangeText(
    dynamic recent,
    AdminBookingModel? matchedBooking,
  ) {
    DateTime? start;
    DateTime? end;

    if (matchedBooking != null) {
      start = matchedBooking.rentalStartDate;
      end = matchedBooking.rentalEndDate;
    }

    try {
      start ??= recent.rentalStartDate as DateTime?;
      end ??= recent.rentalEndDate as DateTime?;
    } catch (_) {}

    try {
      start ??= DateTime.tryParse(recent.rental_start_date.toString());
      end ??= DateTime.tryParse(recent.rental_end_date.toString());
    } catch (_) {}

    if (start == null || end == null) return '-';

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

class _RecentBookingImage extends StatelessWidget {
  final String imageUrl;

  const _RecentBookingImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.trim().isEmpty
          ? const Center(
              child: Icon(
                Icons.camera_alt_rounded,
                color: AppColors.white,
                size: 28,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyRecentBookingCard extends StatelessWidget {
  const _EmptyRecentBookingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Belum ada pesanan terbaru.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
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
                'Gagal memuat dashboard',
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
