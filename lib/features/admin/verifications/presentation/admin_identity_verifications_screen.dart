import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../data/models/admin_identity_verification_model.dart';
import '../providers/admin_identity_verifications_provider.dart';

class AdminIdentityVerificationsScreen extends ConsumerWidget {
  const AdminIdentityVerificationsScreen({super.key});

  static const _filters = <_VerificationFilter>[
    _VerificationFilter(label: 'Semua', value: null),
    _VerificationFilter(label: 'Pending', value: 'pending'),
    _VerificationFilter(label: 'Approved', value: 'approved'),
    _VerificationFilter(label: 'Rejected', value: 'rejected'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationState = ref.watch(
      adminIdentityVerificationsControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi KTP')),
      body: verificationState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: readableError(error),
          onRetry: () {
            ref
                .read(adminIdentityVerificationsControllerProvider.notifier)
                .refresh();
          },
        ),
        data: (state) {
          return RefreshIndicator(
            onRefresh: () {
              return ref
                  .read(adminIdentityVerificationsControllerProvider.notifier)
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
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = state.selectedStatus == filter.value;

                      return ChoiceChip(
                        label: Text(filter.label),
                        selected: selected,
                        selectedColor: AppColors.black,
                        backgroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.border),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        onSelected: (_) {
                          ref
                              .read(
                                adminIdentityVerificationsControllerProvider
                                    .notifier,
                              )
                              .setStatus(filter.value);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (state.errorMessage != null) ...[
                  _MessageBox(message: state.errorMessage!),
                  const SizedBox(height: 14),
                ],
                if (state.verifications.isEmpty)
                  const _EmptyState()
                else
                  ...state.verifications.map(
                    (verification) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _VerificationCard(
                        verification: verification,
                        onTap: () async {
                          final result = await context.push<bool>(
                            '/admin/verifications/identity/${verification.id}',
                            extra: verification,
                          );

                          if (result == true && context.mounted) {
                            ref
                                .read(
                                  adminIdentityVerificationsControllerProvider
                                      .notifier,
                                )
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

class _VerificationCard extends StatelessWidget {
  final AdminIdentityVerificationModel verification;
  final VoidCallback onTap;

  const _VerificationCard({required this.verification, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                    verification.ktpName.isNotEmpty
                        ? verification.ktpName
                        : verification.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusBadge(status: verification.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              verification.bookingCode,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              verification.customerEmail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    verification.addressText.isEmpty
                        ? 'Lokasi belum tersedia'
                        : verification.addressText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    final color = _color(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _color(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _label(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending_review':
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }
}

class _VerificationFilter {
  final String label;
  final String? value;

  const _VerificationFilter({required this.label, required this.value});
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.textSecondary,
            size: 54,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada verifikasi KTP',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Data verifikasi customer akan muncul di halaman ini.',
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
