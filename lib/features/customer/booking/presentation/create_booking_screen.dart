import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/item_model.dart';
import '../providers/create_booking_provider.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final int itemId;

  const CreateBookingScreen({super.key, required this.itemId});

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createBooking() async {
    final booking = await ref
        .read(createBookingControllerProvider(widget.itemId).notifier)
        .createBooking();

    if (!mounted || booking == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking berhasil dibuat: ${booking.code}')),
    );

    context.go('/customer/bookings/${booking.id}');
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(
      createBookingControllerProvider(widget.itemId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Alat')),
      body: bookingState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _BookingErrorState(
          message: readableError(error),
          onRetry: () {
            ref.invalidate(createBookingControllerProvider(widget.itemId));
          },
        ),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
            children: [
              _ItemSummaryCard(item: state.item),
              const SizedBox(height: 18),
              _CalendarSection(
                state: state,
                onRangeSelected: (start, end, focusedDay) {
                  ref
                      .read(
                        createBookingControllerProvider(widget.itemId).notifier,
                      )
                      .setDateRange(
                        start: start,
                        end: end,
                        focusedDay: focusedDay,
                      );
                },
                onPageChanged: (focusedDay) {
                  ref
                      .read(
                        createBookingControllerProvider(widget.itemId).notifier,
                      )
                      .setDateRange(
                        start: state.startDate,
                        end: state.endDate,
                        focusedDay: focusedDay,
                      );
                },
              ),
              const SizedBox(height: 18),
              _NoteSection(
                controller: _noteController,
                onChanged: (value) {
                  ref
                      .read(
                        createBookingControllerProvider(widget.itemId).notifier,
                      )
                      .setCustomerNote(value);
                },
              ),
              const SizedBox(height: 18),
              if (state.errorMessage != null)
                _MessageBox(message: state.errorMessage!, isSuccess: false),
              if (state.availabilityResult != null)
                _MessageBox(
                  message: state.availabilityResult!.message,
                  isSuccess: state.availabilityResult!.isAvailable,
                ),
              const SizedBox(height: 18),
              AppButton(
                text: state.isCheckingAvailability
                    ? 'Mengecek...'
                    : 'Cek Ketersediaan',
                icon: Icons.event_available_rounded,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                isLoading: state.isCheckingAvailability,
                onPressed:
                    state.isCheckingAvailability ||
                        state.isCreatingBooking ||
                        !state.hasValidDateRange
                    ? null
                    : () {
                        ref
                            .read(
                              createBookingControllerProvider(
                                widget.itemId,
                              ).notifier,
                            )
                            .checkAvailability();
                      },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: bookingState.maybeWhen(
        data: (state) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: AppButton(
                text: state.isCreatingBooking
                    ? 'Membuat Booking...'
                    : 'Buat Booking',
                icon: Icons.shopping_bag_rounded,
                backgroundColor: state.canCreateBooking
                    ? AppColors.black
                    : AppColors.border,
                foregroundColor: state.canCreateBooking
                    ? AppColors.white
                    : AppColors.textSecondary,
                isLoading: state.isCreatingBooking,
                onPressed: state.canCreateBooking ? _createBooking : null,
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _ItemSummaryCard extends StatelessWidget {
  final ItemModel item;

  const _ItemSummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 86,
              height: 86,
              color: AppColors.input,
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.devices_other_rounded,
                      color: AppColors.textSecondary,
                      size: 36,
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return const Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.textSecondary,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.brand} • ${item.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.dailyPrice(item.dailyPrice),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
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

class _CalendarSection extends StatelessWidget {
  final CreateBookingState state;
  final void Function(DateTime? start, DateTime? end, DateTime focusedDay)
  onRangeSelected;
  final void Function(DateTime focusedDay) onPageChanged;

  const _CalendarSection({
    required this.state,
    required this.onRangeSelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 6, 6, 10),
            child: Text(
              'Pilih Tanggal Sewa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TableCalendar(
            firstDay: DateTime(today.year, today.month, today.day),
            lastDay: DateTime(today.year + 1, today.month, today.day),
            focusedDay: state.focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            rangeStartDay: state.startDate,
            rangeEndDay: state.endDate,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            onRangeSelected: onRangeSelected,
            onPageChanged: onPageChanged,
            enabledDayPredicate: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              final normalizedToday = DateTime(
                today.year,
                today.month,
                today.day,
              );

              return !normalizedDay.isBefore(normalizedToday);
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              rangeStartDecoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              rangeHighlightColor: AppColors.primary.withOpacity(0.25),
              weekendTextStyle: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
              defaultTextStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              disabledTextStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.35),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dateRangeText(state.startDate, state.endDate),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeText(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return 'Belum memilih tanggal.';
    }

    if (start != null && end == null) {
      return 'Tanggal mulai: ${start.day}/${start.month}/${start.year}. Pilih tanggal selesai.';
    }

    return 'Tanggal sewa: ${start!.day}/${start.month}/${start.year} - ${end!.day}/${end.month}/${end.year}';
  }
}

class _NoteSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NoteSection({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText:
              'Catatan untuk admin, contoh: digunakan untuk dokumentasi acara kampus.',
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const _MessageBox({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppColors.success.withOpacity(0.12)
            : AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BookingErrorState({required this.message, required this.onRetry});

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
                'Gagal memuat booking',
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
