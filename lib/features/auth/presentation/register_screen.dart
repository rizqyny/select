import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/register_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref
        .read(registerControllerProvider.notifier)
        .register(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          phone: _phoneController.text,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil. Silakan login.')),
      );

      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final state = registerState.asData?.value ?? const RegisterState();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.black,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Buat Akun SELECT',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daftar sebagai customer untuk mulai menyewa alat elektronik.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_rounded),
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
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppButton(
                    text: state.isSubmitting ? 'Mendaftarkan...' : 'Daftar',
                    icon: Icons.person_add_alt_1_rounded,
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text(
                        'Sudah punya akun? Login',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
