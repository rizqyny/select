import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/app_user.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _loginWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final user =
          await ref.read(authControllerProvider.notifier).signInWithGoogle();

      if (!context.mounted) return;

      switch (user.role) {
        case UserRole.admin:
          context.go('/admin/dashboard');
          break;
        case UserRole.customer:
          context.go('/customer/home');
          break;
        case UserRole.unknown:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Role user tidak dikenali. Hubungi admin.'),
            ),
          );
          break;
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(readableError(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome!',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(46),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Masuk menggunakan akun Google untuk mulai menyewa alat elektronik.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 42),
                    AppButton(
                      text: 'Login With Google',
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.textPrimary,
                      icon: Icons.g_mobiledata_rounded,
                      isLoading: isLoading,
                      onPressed: isLoading
                          ? null
                          : () => _loginWithGoogle(context, ref),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Dengan masuk, kamu menyetujui proses autentikasi menggunakan Supabase Auth.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
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
}