import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();

    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin SELECT')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.black,
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName
                          : 'Admin',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Login berhasil sebagai Admin.\nSelanjutnya dashboard admin akan digunakan untuk mengelola alat, booking, user, dan verifikasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Verifikasi KTP Customer',
                icon: Icons.verified_user_rounded,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                onPressed: () {
                  context.push('/admin/verifications/identity');
                },
              ),
              const SizedBox(height: 14),
              const SizedBox(height: 24),
              AppButton(
                text: 'Logout',
                icon: Icons.logout_rounded,
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                onPressed: () => _logout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
