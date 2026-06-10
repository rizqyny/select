import 'package:go_router/go_router.dart';

import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customer/home/customer_home_screen.dart';
import '../../features/customer/items/presentation/item_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/customer/booking/presentation/create_booking_screen.dart';
import '../../features/customer/booking/presentation/booking_detail_screen.dart';
import '../../features/customer/booking/presentation/customer_bookings_screen.dart';
import '../../features/customer/booking/presentation/payment_webview_screen.dart';
import '../../features/customer/verification/presentation/identity_verification_screen.dart';
import '../../data/models/admin_identity_verification_model.dart';
import '../../features/admin/verifications/presentation/admin_identity_verification_detail_screen.dart';
import '../../features/admin/verifications/presentation/admin_identity_verifications_screen.dart';
import '../../data/models/admin_booking_model.dart';
import '../../features/admin/bookings/presentation/admin_booking_detail_screen.dart';
import '../../features/admin/bookings/presentation/admin_bookings_screen.dart';

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
      path: '/customer/booking/create/:itemId',
      name: 'customer-create-booking',
      builder: (context, state) {
        final itemId = int.tryParse(state.pathParameters['itemId'] ?? '') ?? 0;

        return CreateBookingScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: '/customer/bookings',
      name: 'customer-bookings',
      builder: (context, state) => const CustomerBookingsScreen(),
    ),
    GoRoute(
      path: '/customer/bookings/:id',
      name: 'customer-booking-detail',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

        return BookingDetailScreen(bookingId: id);
      },
    ),
    GoRoute(
      path: '/customer/payment-webview',
      name: 'customer-payment-webview',
      builder: (context, state) {
        final args = state.extra as PaymentWebViewArgs?;

        return PaymentWebViewScreen(
          args:
              args ??
              const PaymentWebViewArgs(
                redirectUrl: 'https://app.sandbox.midtrans.com/',
                title: 'Pembayaran',
              ),
        );
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
    GoRoute(
      path: '/admin/verifications/identity',
      name: 'admin-identity-verifications',
      builder: (context, state) => const AdminIdentityVerificationsScreen(),
    ),
    GoRoute(
      path: '/admin/verifications/identity/:id',
      name: 'admin-identity-verification-detail',
      builder: (context, state) {
        final verification = state.extra as AdminIdentityVerificationModel?;

        if (verification == null) {
          return const AdminIdentityVerificationsScreen();
        }

        return AdminIdentityVerificationDetailScreen(
          verification: verification,
        );
      },
    ),
    GoRoute(
      path: '/admin/bookings',
      name: 'admin-bookings',
      builder: (context, state) => const AdminBookingsScreen(),
    ),
    GoRoute(
      path: '/admin/bookings/:id',
      name: 'admin-booking-detail',
      builder: (context, state) {
        final booking = state.extra as AdminBookingModel?;

        if (booking == null) {
          return const AdminBookingsScreen();
        }

        return AdminBookingDetailScreen(booking: booking);
      },
    ),
  ],
);
