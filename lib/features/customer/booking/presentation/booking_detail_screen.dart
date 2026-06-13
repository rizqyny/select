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
      case 'waiting_payment':
        return 'Silakan lakukan pembayaran terlebih dahulu.';
      case 'payment_pending':
        return 'Menunggu konfirmasi pembayaran.';
      case 'paid':
        return 'Pembayaran berhasil. Menunggu admin menyetujui pesanan.';
      case 'rejected':
        return 'Booking ditolak oleh admin.';
      case 'cancelled':
        return 'Booking sudah dibatalkan.';
      case 'expired':
        return 'Booking sudah kedaluwarsa.';
      case 'approved':
        return 'Pesanan sudah disetujui. Silakan verifikasi kondisi awal barang.';
      case 'ongoing':
        return 'Masa sewa sedang berlangsung.';
      case 'completed':
        return 'Booking sudah selesai.';
      default:
        return 'Tidak ada aksi untuk status booking ini.';
    }
  }

  bool _needsBeforeConditionVerification(BookingModel booking) {
    return booking.status == 'approved';
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
      final paymentResult = await ref
          .read(bookingDetailControllerProvider(bookingId).notifier)
          .simulatePaymentPaid();

      if (!context.mounted) return;

      if (paymentResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimulasikan pembayaran berhasil.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pembayaran berhasil. Menunggu admin menyetujui pesanan.',
          ),
        ),
      );
    }
  }

  int _firstItemId(BookingModel booking) {
    if (booking.items.isEmpty) return 0;

    return booking.items.first.itemId;
  }

  Future<void> _openIdentityVerification(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final result = await context.push<bool>(
      '/customer/verifications/identity/${booking.id}',
    );

    if (result == true && context.mounted) {
      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .markIdentityVerificationSubmitted();

      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .refresh();
    }
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
          .markConditionVerificationSubmitted('before_rent');

      await ref
          .read(bookingDetailControllerProvider(booking.id).notifier)
          .refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(bookingDetailControllerProvider(bookingId));

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
            color: AppColors.primary,
            onRefresh: () {
              return ref
                  .read(bookingDetailControllerProvider(bookingId).notifier)
                  .refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 132),
              children: [
                _BookingSummaryCard(booking: state.booking),
                const SizedBox(height: 16),
                _IdentityVerificationCard(
                  booking: state.booking,
                  hasSubmittedIdentityVerification:
                      state.hasSubmittedIdentityVerification,
                ),
                const SizedBox(height: 16),
                _ConditionVerificationCard(
                  booking: state.booking,
                  hasSubmittedBeforeConditionVerification:
                      state.hasSubmittedBeforeConditionVerification,
                ),
                const SizedBox(height: 16),
                _PaymentVerificationCard(
                  booking: state.booking,
                  payment: state.payment,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _MessageBox(message: state.errorMessage!),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: detailState.maybeWhen(
        data: (state) {
          return SafeArea(
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
              child: _CustomerActionButtons(
                state: state,
                bottomStatusMessage: _bottomStatusMessage,
                needsBeforeConditionVerification:
                    _needsBeforeConditionVerification,
                onPay: () => _createOrOpenPayment(context, ref, state),
                onOpenIdentityVerification: () {
                  _openIdentityVerification(context, ref, state.booking);
                },
                onOpenConditionVerification: () {
                  _openConditionVerification(
                    context,
                    ref,
                    state.booking,
                    'before_rent',
                  );
                },
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final BookingModel booking;

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
              const _BookingAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesanan Saya',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${booking.code}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
  final BookingModel booking;

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
        final displayDailyPrice = item.dailyPrice > 0
            ? item.dailyPrice
            : booking.fallbackDailyPricePerItem;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '1x',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (displayDailyPrice > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.dailyPrice(displayDailyPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _IdentityVerificationCard extends StatelessWidget {
  final BookingModel booking;
  final bool hasSubmittedIdentityVerification;

  const _IdentityVerificationCard({
    required this.booking,
    required this.hasSubmittedIdentityVerification,
  });

  @override
  Widget build(BuildContext context) {
    final status = _identityStatus();

    return _VerificationCard(
      title: 'Verifikasi KTP',
      status: status,
      icon: Icons.badge_rounded,
      child: _VerificationInfoBox(
        icon: _identityIcon(status),
        title: _identityTitle(status),
        subtitle: _identityMessage(),
      ),
    );
  }

  _VerificationViewStatus _identityStatus() {
    if (_isFailedStatus(booking.status)) {
      return _VerificationViewStatus.rejected;
    }

    if (booking.needsIdentityVerification) {
      if (hasSubmittedIdentityVerification) {
        return _VerificationViewStatus.pending;
      }

      return _VerificationViewStatus.pending;
    }

    return _VerificationViewStatus.approved;
  }

  IconData _identityIcon(_VerificationViewStatus status) {
    if (status == _VerificationViewStatus.approved) {
      return Icons.verified_user_rounded;
    }

    if (status == _VerificationViewStatus.rejected) {
      return Icons.cancel_rounded;
    }

    return hasSubmittedIdentityVerification
        ? Icons.hourglass_top_rounded
        : Icons.badge_rounded;
  }

  String _identityTitle(_VerificationViewStatus status) {
    if (status == _VerificationViewStatus.approved) {
      return 'KTP Sudah Disetujui';
    }

    if (status == _VerificationViewStatus.rejected) {
      return 'Verifikasi Tidak Dilanjutkan';
    }

    if (hasSubmittedIdentityVerification) {
      return 'Menunggu Persetujuan Admin';
    }

    return 'Menunggu Verifikasi KTP';
  }

  String _identityMessage() {
    if (_isFailedStatus(booking.status)) {
      return _statusFailedMessage(booking.status);
    }

    if (booking.needsIdentityVerification) {
      if (hasSubmittedIdentityVerification) {
        return 'Verifikasi KTP sudah dikirim. Menunggu admin melakukan pengecekan dan persetujuan.';
      }

      return 'Silakan kirim verifikasi KTP terlebih dahulu agar proses sewa dapat dilanjutkan.';
    }

    return 'KTP sudah diverifikasi. Customer dapat melanjutkan proses pembayaran atau tahap berikutnya.';
  }
}

class _ConditionVerificationCard extends StatelessWidget {
  final BookingModel booking;
  final bool hasSubmittedBeforeConditionVerification;

  const _ConditionVerificationCard({
    required this.booking,
    required this.hasSubmittedBeforeConditionVerification,
  });

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
          _ConditionPreview(
            status: status,
            hasSubmittedBeforeConditionVerification:
                hasSubmittedBeforeConditionVerification,
          ),
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

  _VerificationViewStatus _conditionStatus(BookingModel booking) {
    if (_isFailedStatus(booking.status)) {
      return _VerificationViewStatus.rejected;
    }

    if (booking.status == 'ongoing' || booking.status == 'completed') {
      return _VerificationViewStatus.approved;
    }

    return _VerificationViewStatus.pending;
  }

  String _conditionMessage(String status) {
    switch (status) {
      case 'pending_verification':
        return 'Verifikasi kondisi belum dapat diproses sebelum KTP disetujui admin.';
      case 'waiting_payment':
        return 'Menunggu pembayaran selesai sebelum verifikasi kondisi awal barang.';
      case 'payment_pending':
        return 'Menunggu konfirmasi pembayaran terlebih dahulu.';
      case 'paid':
        return 'Pembayaran berhasil. Menunggu admin menyetujui pesanan.';
      case 'approved':
        if (hasSubmittedBeforeConditionVerification) {
          return 'Verifikasi kondisi awal barang sudah dikirim. Menunggu admin memulai masa sewa.';
        }
        return 'Pesanan sudah disetujui. Silakan kirim verifikasi kondisi awal barang.';
      case 'ongoing':
        return 'Kondisi awal sudah diverifikasi dan masa sewa sedang berlangsung.';
      case 'completed':
        return 'Sewa sudah selesai.';
      case 'rejected':
        return 'Pesanan sudah ditolak oleh admin.';
      case 'cancelled':
        return 'Pesanan sudah dibatalkan.';
      case 'expired':
        return 'Pesanan sudah kedaluwarsa.';
      default:
        return 'Status kondisi mengikuti proses booking saat ini.';
    }
  }
}

class _PaymentVerificationCard extends StatelessWidget {
  final BookingModel booking;
  final PaymentModel? payment;

  const _PaymentVerificationCard({
    required this.booking,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final currentPayment = payment;
    final status = _paymentStatus(booking, currentPayment);

    return _VerificationCard(
      title: 'Pembayaran',
      status: status,
      icon: Icons.payments_rounded,
      child: currentPayment == null
          ? _VerificationInfoBox(
              icon: Icons.receipt_long_rounded,
              title: 'Informasi Pembayaran',
              subtitle: _emptyPaymentMessage(booking),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VerificationInfoBox(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Detail Pembayaran',
                  subtitle:
                      'Provider: ${_emptyDash(currentPayment.provider)}\nOrder ID: ${_emptyDash(currentPayment.externalOrderId)}\nStatus: ${_emptyDash(currentPayment.status)}\nJumlah: ${CurrencyFormatter.rupiah(currentPayment.grossAmount)}',
                ),
              ],
            ),
    );
  }

  _VerificationViewStatus _paymentStatus(
    BookingModel booking,
    PaymentModel? payment,
  ) {
    final paymentStatus =
        payment?.status.toLowerCase() ??
        booking.paymentStatus?.toLowerCase() ??
        '';

    final alreadyPaid =
        payment?.isPaid == true ||
        booking.status == 'paid' ||
        booking.status == 'approved' ||
        booking.status == 'ongoing' ||
        booking.status == 'completed' ||
        paymentStatus == 'paid' ||
        paymentStatus == 'settlement' ||
        paymentStatus == 'capture';

    if (alreadyPaid) {
      return _VerificationViewStatus.approved;
    }

    if (_isFailedStatus(booking.status)) {
      return _VerificationViewStatus.rejected;
    }

    return _VerificationViewStatus.pending;
  }

  String _emptyPaymentMessage(BookingModel booking) {
    if (booking.needsIdentityVerification) {
      return 'Pembayaran belum tersedia. Customer harus melakukan verifikasi KTP dan menunggu persetujuan admin.';
    }

    if (booking.canPay) {
      return 'Pembayaran belum dibuat. Tekan tombol Bayar Sekarang untuk membuat pembayaran.';
    }

    return 'Pembayaran belum tersedia untuk status booking ini.';
  }

  String _emptyDash(String value) {
    return value.trim().isEmpty ? '-' : value;
  }
}

class _CustomerActionButtons extends StatelessWidget {
  final BookingDetailState state;
  final String Function(String status) bottomStatusMessage;
  final bool Function(BookingModel booking) needsBeforeConditionVerification;
  final VoidCallback onPay;
  final VoidCallback onOpenIdentityVerification;
  final VoidCallback onOpenConditionVerification;

  const _CustomerActionButtons({
    required this.state,
    required this.bottomStatusMessage,
    required this.needsBeforeConditionVerification,
    required this.onPay,
    required this.onOpenIdentityVerification,
    required this.onOpenConditionVerification,
  });

  @override
  Widget build(BuildContext context) {
    final booking = state.booking;
    final payment = state.payment;

    final paymentStatus =
        payment?.status.toLowerCase() ??
        booking.paymentStatus?.toLowerCase() ??
        '';

    final alreadyPaid =
        payment?.isPaid == true ||
        booking.status == 'paid' ||
        paymentStatus == 'paid' ||
        paymentStatus == 'settlement' ||
        paymentStatus == 'capture';

    final needsConditionVerification = needsBeforeConditionVerification(
      booking,
    );

    if (booking.needsIdentityVerification) {
      if (state.hasSubmittedIdentityVerification) {
        return const Text(
          'Verifikasi KTP sudah dikirim. Menunggu persetujuan admin.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.w900,
            height: 1.4,
          ),
        );
      }

      return AppButton(
        text: 'Verifikasi KTP',
        icon: Icons.badge_rounded,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        onPressed: onOpenIdentityVerification,
      );
    }

    if (booking.canPay && !alreadyPaid) {
      return AppButton(
        text: state.isCreatingPayment
            ? 'Membuat Pembayaran...'
            : 'Bayar Sekarang',
        icon: Icons.payment_rounded,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        isLoading: state.isCreatingPayment,
        onPressed: state.isCreatingPayment ? null : onPay,
      );
    }

    if (booking.status == 'payment_pending') {
      return const Text(
        'Menunggu konfirmasi pembayaran.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.warning,
          fontWeight: FontWeight.w900,
          height: 1.4,
        ),
      );
    }

    if (needsConditionVerification) {
      if (state.hasSubmittedBeforeConditionVerification) {
        return const Text(
          'Verifikasi kondisi awal barang sudah dikirim. Menunggu admin memulai masa sewa.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.w900,
            height: 1.4,
          ),
        );
      }

      return AppButton(
        text: 'Verifikasi Kondisi Awal Barang',
        icon: Icons.fact_check_rounded,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        onPressed: onOpenConditionVerification,
      );
    }

    if (booking.status == 'ongoing' || booking.status == 'active') {
      return const Text(
        'Masa sewa sedang berjalan.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w900,
          height: 1.4,
        ),
      );
    }

    if (booking.status == 'completed') {
      return const Text(
        'Booking sudah selesai.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w900,
          height: 1.4,
        ),
      );
    }

    return Text(
      bottomStatusMessage(booking.status),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w900,
      ),
    );
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

class _ConditionPreview extends StatelessWidget {
  final _VerificationViewStatus status;
  final bool hasSubmittedBeforeConditionVerification;

  const _ConditionPreview({
    required this.status,
    required this.hasSubmittedBeforeConditionVerification,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = status == _VerificationViewStatus.approved;
    final isRejected = status == _VerificationViewStatus.rejected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApproved
            ? AppColors.success.withOpacity(0.08)
            : isRejected
            ? AppColors.danger.withOpacity(0.08)
            : AppColors.input,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApproved
              ? AppColors.success.withOpacity(0.25)
              : isRejected
              ? AppColors.danger.withOpacity(0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isApproved
                ? Icons.check_circle_rounded
                : isRejected
                ? Icons.cancel_rounded
                : Icons.hourglass_top_rounded,
            color: isApproved
                ? AppColors.success
                : isRejected
                ? AppColors.danger
                : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _previewMessage(isApproved, isRejected),
              style: TextStyle(
                color: isApproved
                    ? AppColors.success
                    : isRejected
                    ? AppColors.danger
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _previewMessage(bool isApproved, bool isRejected) {
    if (isApproved) return 'Kondisi awal sudah disetujui.';
    if (isRejected) return 'Verifikasi kondisi tidak dapat dilanjutkan.';
    if (hasSubmittedBeforeConditionVerification) {
      return 'Verifikasi kondisi awal sudah dikirim.';
    }
    return 'Menunggu verifikasi kondisi awal barang.';
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
      case 'active':
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
      case 'active':
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

class _BookingAvatar extends StatelessWidget {
  const _BookingAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.receipt_long_rounded,
          color: AppColors.white,
          size: 24,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
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

bool _isFailedStatus(String status) {
  return status == 'rejected' || status == 'cancelled' || status == 'expired';
}

String _statusFailedMessage(String status) {
  switch (status) {
    case 'rejected':
      return 'Pesanan sudah ditolak oleh admin.';
    case 'cancelled':
      return 'Pesanan sudah dibatalkan.';
    case 'expired':
      return 'Pesanan sudah kedaluwarsa.';
    default:
      return 'Proses booking tidak dapat dilanjutkan.';
  }
}
