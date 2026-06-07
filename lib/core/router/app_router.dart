import 'package:go_router/go_router.dart';

import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customer/home/customer_home_screen.dart';
import '../../features/customer/items/presentation/item_detail_screen.dart';
import '../../features/customer/verification/presentation/identity_verification_screen.dart';
import '../../features/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/customer/home',
      name: 'customer-home',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/customer/items/:id',
      name: 'customer-item-detail',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

        return ItemDetailScreen(itemId: id);
      },
    ),
    GoRoute(
      path: '/customer/verifications/identity/:bookingId',
      name: 'customer-identity-verification',
      builder: (context, state) {
        final bookingId =
            int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 0;

        return IdentityVerificationScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/admin/dashboard',
      name: 'admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
