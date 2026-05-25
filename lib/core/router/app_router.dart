import 'package:go_router/go_router.dart';

import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customer/home/customer_home_screen.dart';
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
      path: '/admin/dashboard',
      name: 'admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);