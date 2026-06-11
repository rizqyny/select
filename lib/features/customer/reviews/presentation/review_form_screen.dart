import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/review_form_provider.dart';

class ReviewFormScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final int itemId;

  const ReviewFormScreen({
    super.key,
    required this.bookingId,
    required this.itemId,
  });

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  late final TextEditingController _commentController;

  ReviewFormArgs get _args {
    return ReviewFormArgs(
      bookingId: widget.bookingId,
      itemId: widget.itemId,
    );
  }

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref
        .read(reviewFormControllerProvider(_args).notifier)
        .setComment(_commentController.text);

    final success =
        await ref.read(reviewFormControllerProvider(_args).notifier).submit();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review berhasil dikirim.'),
        ),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewFormControllerProvider(_args));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Barang'),
      ),
      body: reviewState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Text(error.toString()),
        ),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 42,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Bagaimana pengalamanmu?',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Berikan rating dan komentar setelah penyewaan selesai.',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _RatingCard(
                rating: state.rating,
                onChanged: (rating) {
                  ref
                      .read(reviewFormControllerProvider(_args).notifier)
                      .setRating(rating);
                },
              ),
              const SizedBox(height: 18),
              _CommentCard(controller: _commentController),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 18),
                _MessageBox(message: state.errorMessage!),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: reviewState.maybeWhen(
        data: (state) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: AppButton(
                text: 'Kirim Review',
                icon: Icons.send_rounded,
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                isLoading: state.isSubmitting,
                onPressed:
                    state.canSubmit && !state.isSubmitting ? _submit : null,
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _RatingCard({
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Rating',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final value = index + 1;
          final selected = value <= rating;

          return IconButton(
            onPressed: () => onChanged(value),
            icon: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 38,
            ),
          );
        }),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final TextEditingController controller;

  const _CommentCard({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Komentar',
      child: TextField(
        controller: controller,
        maxLines: 5,
        decoration: InputDecoration(
          hintText:
              'Contoh: Barang bagus, admin responsif, dan proses sewa jelas.',
          filled: true,
          fillColor: AppColors.input,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.black),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;

  const _MessageBox({
    required this.message,
  });

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