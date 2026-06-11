import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/models/review_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/review_repository.dart';

class ReviewFormArgs {
  final int bookingId;
  final int itemId;

  const ReviewFormArgs({required this.bookingId, required this.itemId});

  String get localKey => 'review_submitted_${bookingId}_$itemId';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewFormArgs &&
            other.bookingId == bookingId &&
            other.itemId == itemId;
  }

  @override
  int get hashCode => Object.hash(bookingId, itemId);
}

class ReviewFormState {
  final int rating;
  final String comment;
  final bool isSubmitting;
  final String? errorMessage;
  final ReviewModel? result;

  const ReviewFormState({
    this.rating = 5,
    this.comment = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.result,
  });

  bool get canSubmit {
    return rating >= 1 &&
        rating <= 5 &&
        comment.trim().isNotEmpty &&
        !isSubmitting;
  }

  ReviewFormState copyWith({
    int? rating,
    String? comment,
    bool? isSubmitting,
    Object? errorMessage = _unset,
    Object? result = _unset,
  }) {
    return ReviewFormState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      result: identical(result, _unset) ? this.result : result as ReviewModel?,
    );
  }
}

const Object _unset = Object();

final reviewFormControllerProvider =
    AsyncNotifierProvider.family<
      ReviewFormController,
      ReviewFormState,
      ReviewFormArgs
    >(ReviewFormController.new);

class ReviewFormController extends AsyncNotifier<ReviewFormState> {
  final ReviewFormArgs args;

  ReviewFormController(this.args);

  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  @override
  FutureOr<ReviewFormState> build() {
    return const ReviewFormState();
  }

  void setRating(int rating) {
    final current = state.value ?? const ReviewFormState();

    state = AsyncData(current.copyWith(rating: rating, errorMessage: null));
  }

  void setComment(String comment) {
    final current = state.value ?? const ReviewFormState();

    state = AsyncData(current.copyWith(comment: comment, errorMessage: null));
  }

  Future<bool> submit() async {
    final current = state.value ?? const ReviewFormState();

    if (!current.canSubmit) return false;

    state = AsyncData(current.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final result = await _repository.createReview(
        bookingId: args.bookingId,
        itemId: args.itemId,
        rating: current.rating,
        comment: current.comment,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(args.localKey, true);

      final latest = state.value ?? current;

      state = AsyncData(latest.copyWith(isSubmitting: false, result: result));

      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }
}
