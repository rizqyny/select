import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/admin_dashboard_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/admin_dashboard_repository.dart';

final adminDashboardControllerProvider =
    AsyncNotifierProvider<AdminDashboardController, AdminDashboardModel>(
  AdminDashboardController.new,
);

class AdminDashboardController extends AsyncNotifier<AdminDashboardModel> {
  AdminDashboardRepository get _repository =>
      ref.read(adminDashboardRepositoryProvider);

  @override
  FutureOr<AdminDashboardModel> build() async {
    return _repository.fetchDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      return _repository.fetchDashboard();
    });
  }
}