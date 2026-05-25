import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/env/app_env.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/app_user.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    try {
      final user =
          await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
                email: _emailController.text,
                password: _passwordController.text,
              );

      if (!mounted) return;
      _redirectByRole(user);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(readableError(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final user =
          await ref.read(authControllerProvider.notifier).signInWithGoogle();

      if (!mounted) return;
      _redirectByRole(user);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(readableError(error)),
          backgroundColor: AppColors.danger,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role user tidak dikenali. Hubungi admin.'),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(46),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
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
                        const SizedBox(height: 10),
                        const Text(
                          'Masuk menggunakan email dan password akun SELECT.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email_rounded),
                            hintText: 'Email',
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }

                            if (!email.contains('@')) {
                              return 'Format email tidak valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _loginWithEmailPassword(),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_rounded),
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';

                            if (password.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }

                            if (password.length < 6) {
                              return 'Password minimal 6 karakter';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        AppButton(
                          text: 'Login',
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.black,
                          isLoading: isLoading,
                          onPressed:
                              isLoading ? null : _loginWithEmailPassword,
                        ),

                        if (AppEnv.isGoogleConfigured) ...[
                          const SizedBox(height: 22),
                          const Text(
                            '- Atau -',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          AppButton(
                            text: 'Login With Google',
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.textPrimary,
                            icon: Icons.g_mobiledata_rounded,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _loginWithGoogle,
                          ),
                        ],

                        const SizedBox(height: 22),

                        const Text(
                          'Gunakan akun yang sudah terdaftar di sistem SELECT.',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}