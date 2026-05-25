import 'package:go_router/go_router.dart';

import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customer/home/customer_home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/maps/presentation/location_map_screen.dart';
import '../../features/verification/models/verification_capture_result.dart';
import '../../features/verification/presentation/verification_capture_screen.dart';

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
      path: '/admin/dashboard',
      name: 'admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/verification/capture',
      name: 'verification-capture',
      builder: (context, state) {
        final args = state.extra as VerificationCaptureArgs?;

        return VerificationCaptureScreen(
          args: args ??
              const VerificationCaptureArgs(
                type: VerificationCaptureType.identity,
              ),
        );
      },
    ),
    GoRoute(
      path: '/maps/location',
      name: 'location-map',
      builder: (context, state) {
        final args = state.extra as LocationMapArgs?;

        return LocationMapScreen(
          args: args ??
              const LocationMapArgs(
                latitude: -8.164846,
                longitude: 113.715,
                title: 'Lokasi Customer',
                addressText: 'Jember',
              ),
        );
      },
    ),
  ],
);