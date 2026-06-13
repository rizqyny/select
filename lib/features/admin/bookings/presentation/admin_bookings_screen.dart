import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../data/models/admin_booking_model.dart';
import '../providers/admin_bookings_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  final _searchController = TextEditingController();
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
    _BookingTab(label: 'Diproses', statuses: ['approved']),
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
      ref.read(adminBookingsControllerProvider.notifier).setStatus(null);
    });

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(adminBookingsControllerProvider.notifier).refresh();
  }

  List<AdminBookingModel> _visibleBookings(List<AdminBookingModel> bookings) {
    final selectedTab = _tabs[_selectedTabIndex];
    final query = _searchController.text.trim().toLowerCase();

    return bookings.where((booking) {
      final matchStatus = selectedTab.statuses.contains(booking.status);

      if (!matchStatus) return false;

      if (query.isEmpty) return true;

      final itemText = booking.items.map((item) => item.itemName).join(' ');
      final searchableText =
          '${booking.code} ${booking.customerName} ${booking.customerEmail} $itemText'
              .toLowerCase();

      return searchableText.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(adminBookingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sewa',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: bookingsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) =>
            _ErrorState(message: readableError(error), onRetry: _refresh),
        data: (state) {
          final visibleBookings = _visibleBookings(state.bookings);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                _SearchBox(
                  controller: _searchController,
                  onClear: () {
                    _searchController.clear();
                  },
                ),
                const SizedBox(height: 16),
                _BookingTabs(
                  tabs: _tabs,
                  selectedIndex: _selectedTabIndex,
                  onSelected: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pesanan Terbaru',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),

                if (state.errorMessage != null) ...[
                  _MessageBox(message: state.errorMessage!),
                  const SizedBox(height: 14),
                ],

                if (visibleBookings.isEmpty)
                  _EmptyState(tabLabel: _tabs[_selectedTabIndex].label)
                else
                  ...visibleBookings.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _BookingCard(
                        booking: booking,
                        onTap: () async {
                          final result = await context.push<bool>(
                            '/admin/bookings/${booking.id}',
                            extra: booking,
                          );

                          if (result == true && context.mounted) {
                            ref
                                .read(adminBookingsControllerProvider.notifier)
                                .refresh();
                          }
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBox({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Cari pesanan...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 26),
                decoration: BoxDecoration(
                  color: selected ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.label,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final AdminBookingModel booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final itemText = _itemText(booking);
    final dateText = _dateRangeText(
      booking.rentalStartDate,
      booking.rentalEndDate,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _CustomerAvatar(name: booking.customerName),
                const SizedBox(width: 12),
                Expanded(child: _CustomerHeader(booking: booking)),
                const SizedBox(width: 10),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 13),
            _InfoLine(icon: Icons.camera_alt_outlined, value: itemText),
            const SizedBox(height: 9),
            _InfoLine(icon: Icons.calendar_today_outlined, value: dateText),
            const SizedBox(height: 9),
            _InfoLine(
              icon: Icons.payments_outlined,
              value: CurrencyFormatter.rupiah(booking.totalAmount),
            ),
          ],
        ),
      ),
    );
  }

  static String _itemText(AdminBookingModel booking) {
    if (booking.items.isEmpty) return 'Data barang belum tersedia';

    final names = booking.items
        .map((item) => item.itemName.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.isEmpty) return 'Data barang belum tersedia';

    if (names.length <= 2) {
      return names.join(', ');
    }

    return '${names.take(2).join(', ')} +${names.length - 2} item';
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

class _CustomerHeader extends StatelessWidget {
  final AdminBookingModel booking;

  const _CustomerHeader({required this.booking});

  @override
  Widget build(BuildContext context) {
    final name = booking.customerName.trim().isEmpty
        ? 'Customer'
        : booking.customerName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _displayCode(booking.code),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _displayCode(String code) {
    final clean = code.trim();

    if (clean.isEmpty) return '#-';
    if (clean.startsWith('#')) return clean;

    return '#$clean';
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
      clipBehavior: Clip.antiAlias,
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoLine({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
        color: color.withValues(alpha: 0.12),
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

class _MessageBox extends StatelessWidget {
  final String message;

  const _MessageBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
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

class _EmptyState extends StatelessWidget {
  final String tabLabel;

  const _EmptyState({required this.tabLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
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
            size: 54,
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
            'Data booking customer akan muncul sesuai statusnya di halaman ini.',
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
                'Gagal memuat sewa',
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
