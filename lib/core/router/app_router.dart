import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:select/features/customer/notifications/presentation/notifications_screen.dart';
import 'package:select/features/customer/profile/presentation/profile_screen.dart';

import '../../data/models/admin_booking_model.dart';
import '../../data/models/admin_condition_verification_model.dart';
import '../../data/models/admin_identity_verification_model.dart';
import '../../data/models/admin_item_model.dart';

import '../../features/admin/bookings/presentation/admin_booking_detail_screen.dart';
import '../../features/admin/bookings/presentation/admin_bookings_screen.dart';
import '../../features/admin/common/admin_shell_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/items/presentation/admin_item_form_screen.dart';
import '../../features/admin/items/presentation/admin_items_screen.dart';
import '../../features/admin/users/presentation/admin_users_screen.dart';
import '../../features/admin/verifications/presentation/admin_condition_verification_detail_screen.dart';
import '../../features/admin/verifications/presentation/admin_condition_verifications_screen.dart';
import '../../features/admin/verifications/presentation/admin_identity_verification_detail_screen.dart';
import '../../features/admin/verifications/presentation/admin_identity_verifications_screen.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

import '../../features/customer/booking/presentation/booking_detail_screen.dart';
import '../../features/customer/booking/presentation/create_booking_screen.dart';
import '../../features/customer/booking/presentation/customer_bookings_screen.dart';
import '../../features/customer/booking/presentation/payment_webview_screen.dart';
import '../../features/customer/home/customer_home_screen.dart';
import '../../features/customer/items/presentation/item_detail_screen.dart';
import '../../features/customer/presentation/customer_shell_screen.dart';
import '../../features/customer/reviews/presentation/review_form_screen.dart';
import '../../features/customer/verification/presentation/condition_verification_screen.dart';
import '../../features/customer/verification/presentation/identity_verification_screen.dart';
import '../../features/customer/favorites/presentation/favorites_screen.dart';

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
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),

    GoRoute(
      path: '/customer/notifications',
      name: 'customer-notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // =========================
    // CUSTOMER MAIN ROUTES WITH NAVBAR
    // =========================
    ShellRoute(
      builder: (context, state, child) {
        return CustomerShellScreen(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/customer/home',
          name: 'customer-home',
          builder: (context, state) => const CustomerHomeScreen(),
        ),
        GoRoute(
          path: '/customer/bookings',
          name: 'customer-bookings',
          builder: (context, state) => const CustomerBookingsScreen(),
        ),
        GoRoute(
          path: '/customer/favorites',
          name: 'customer-favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/customer/profile',
          name: 'customer-profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // =========================
    // CUSTOMER DETAIL / ACTION ROUTES WITHOUT NAVBAR
    // =========================
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
      path: '/customer/verifications/condition/:bookingId/:itemId/:type',
      name: 'customer-condition-verification',
      builder: (context, state) {
        final bookingId =
            int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 0;
        final itemId = int.tryParse(state.pathParameters['itemId'] ?? '') ?? 0;
        final type = state.pathParameters['type'] ?? 'before_rent';

        return ConditionVerificationScreen(
          bookingId: bookingId,
          itemId: itemId,
          type: type,
        );
      },
    ),
    GoRoute(
      path: '/customer/reviews/create/:bookingId/:itemId',
      name: 'customer-create-review',
      builder: (context, state) {
        final bookingId =
            int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 0;
        final itemId = int.tryParse(state.pathParameters['itemId'] ?? '') ?? 0;

        return ReviewFormScreen(bookingId: bookingId, itemId: itemId);
      },
    ),

    // =========================
    // ADMIN MAIN ROUTES WITH NAVBAR
    // =========================
    ShellRoute(
      builder: (context, state, child) {
        return AdminShellScreen(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          name: 'admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/bookings',
          name: 'admin-bookings',
          builder: (context, state) => const AdminBookingsScreen(),
        ),
        GoRoute(
          path: '/admin/verifications/identity',
          name: 'admin-identity-verifications',
          builder: (context, state) => const AdminIdentityVerificationsScreen(),
        ),
        GoRoute(
          path: '/admin/verifications/condition',
          name: 'admin-condition-verifications',
          builder: (context, state) =>
              const AdminConditionVerificationsScreen(),
        ),
        GoRoute(
          path: '/admin/items',
          name: 'admin-items',
          builder: (context, state) => const AdminItemsScreen(),
        ),
      ],
    ),

    // =========================
    // ADMIN DETAIL / ACTION ROUTES WITHOUT NAVBAR
    // =========================
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
      path: '/admin/verifications/condition/:id',
      name: 'admin-condition-verification-detail',
      builder: (context, state) {
        final extra = state.extra;

        if (extra is AdminConditionVerificationModel) {
          return AdminConditionVerificationDetailScreen(verification: extra);
        }

        return const Scaffold(
          body: Center(child: Text('Data verifikasi kondisi tidak ditemukan.')),
        );
      },
    ),
    GoRoute(
      path: '/admin/items/create',
      name: 'admin-create-item',
      builder: (context, state) {
        return const AdminItemFormScreen();
      },
    ),
    GoRoute(
      path: '/admin/items/:id/edit',
      name: 'admin-edit-item',
      builder: (context, state) {
        final item = state.extra as AdminItemModel?;

        if (item == null) {
          return const AdminItemFormScreen();
        }

        return AdminItemFormScreen(item: item);
      },
    ),
    GoRoute(
      path: '/admin/users',
      name: 'admin-users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
  ],
);
