import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/error_message.dart';
import '../../data/models/app_user.dart';
import '../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_checkAuth);
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      await ref.read(authControllerProvider.notifier).loadCurrentUser();

      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;

      if (!mounted) return;

      if (user == null) {
        context.go('/login');
        return;
      }

      _redirectByRole(user);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(readableError(error))),
      );

      context.go('/login');
    }
  }

  void _redirectByRole(AppUser user) {
    switch (user.role) {
      case UserRole.admin:
        context.go('/admin/dashboard');
        break;
      case UserRole.customer:
        context.go('/customer/home');
        break;
      case UserRole.unknown:
        context.go('/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Text(
          'SELECT',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
      ),
    );
  }
}