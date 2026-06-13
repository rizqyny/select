import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _hasFilledInitialValue = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          fullName: _nameController.text,
          phone: _phoneController.text,
        );

    if (!mounted) return;

    if (success) {
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      bottomNavigationBar: profileState.maybeWhen(
        data: (state) {
          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
              decoration: const BoxDecoration(color: AppColors.background),
              child: AppButton(
                text: state.isUpdating ? 'Menyimpan...' : 'Simpan Perubahan',
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                isLoading: state.isUpdating,
                onPressed: state.isUpdating ? null : _submit,
              ),
            ),
          );
        },
        orElse: () => null,
      ),
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _ErrorState(
          message: readableError(error),
          onRetry: () {
            ref.read(profileControllerProvider.notifier).refresh();
          },
        ),
        data: (state) {
          final profile = state.profile;

          if (!_hasFilledInitialValue) {
            _nameController.text = profile.fullName;
            _emailController.text = profile.email;
            _phoneController.text = profile.phone ?? '';
            _hasFilledInitialValue = true;
          }

          return RefreshIndicator(
            onRefresh: () async {
              _hasFilledInitialValue = false;
              await ref.read(profileControllerProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 130),
              children: [
                Center(
                  child: _AvatarCircle(
                    fullName: profile.fullName,
                    avatarUrl: _safeAvatarUrl(profile),
                    size: 112,
                  ),
                ),
                const SizedBox(height: 34),
                const _FieldLabel(text: 'Nama Lengkap'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Nama lengkap'),
                ),
                const SizedBox(height: 22),
                const _FieldLabel(text: 'Email'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 22),
                const _FieldLabel(text: 'Nomor HP'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: 'Nomor HP'),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _SmallInfoCard(
                        icon: Icons.verified_user_outlined,
                        label: 'Status Akun',
                        value: profile.isActive ? 'Terverifikasi' : 'Nonaktif',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SmallInfoCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'Bergabung',
                        value: _joinedText(profile),
                      ),
                    ),
                  ],
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 18),
                  _MessageBox(message: state.errorMessage!, isError: true),
                ],
                if (state.successMessage != null) ...[
                  const SizedBox(height: 18),
                  _MessageBox(message: state.successMessage!, isError: false),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static String _safeAvatarUrl(Object profile) {
    try {
      final dynamic value = profile;
      final raw = value.avatarPath?.toString() ?? '';

      if (raw.trim().isNotEmpty &&
          raw.startsWith('http') &&
          !raw.contains('example.com')) {
        return raw.trim();
      }
    } catch (_) {}

    return '';
  }

  static String _joinedText(Object profile) {
    try {
      final dynamic value = profile;
      final DateTime? createdAt = value.createdAt as DateTime?;

      if (createdAt == null) return '-';

      return '${_monthName(createdAt.month)} ${createdAt.year}';
    } catch (_) {
      return '-';
    }
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

    if (month < 1 || month > 12) return '-';

    return months[month];
  }
}

class _AvatarCircle extends StatelessWidget {
  final String fullName;
  final String avatarUrl;
  final double size;

  const _AvatarCircle({
    required this.fullName,
    required this.avatarUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(fullName);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl.trim().isEmpty
            ? Container(
                color: AppColors.primary,
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary,
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty || parts.first.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SmallInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SmallInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
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

class _MessageBox extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageBox({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
                'Gagal memuat profil',
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
