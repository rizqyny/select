class ApiConstants {
  const ApiConstants._();

  static const usersMe = '/users/me';

  static const categories = '/categories';
  static const items = '/items';
  static String itemDetail(int id) => '/items/$id';
  static String itemReviews(int itemId) => '/items/$itemId/reviews';
  static String favoriteByItem(int itemId) => '/favorites/$itemId';

  static const checkAvailability = '/bookings/check-availability';
  static const createBooking = '/bookings';
  static const myBookings = '/bookings/my';
  static String bookingDetail(int id) => '/bookings/$id';
  static String cancelBooking(int id) => '/bookings/$id/cancel';
  static String createPayment(int bookingId) => '/payments/create/$bookingId';
  static String paymentByBooking(int bookingId) =>
      '/payments/booking/$bookingId';

  static const registerDevice = '/notifications/register-device';
  static const myNotifications = '/notifications/my';

  static const identityVerification = '/verifications/identity';
  static const conditionVerification = '/verifications/condition';

  static const signedUploadUrl = '/storage/signed-upload-url';
  static const signedReadUrl = '/storage/signed-read-url';
  static const publicUrl = '/storage/public-url';

  static const myFavorites = '/favorites/my';
  static const myReviews = '/reviews/my';

  static const adminDashboard = '/admin/dashboard';
  static const adminBookings = '/admin/bookings';
  static const adminUsers = '/admin/users';
  static const adminItems = '/items';
  static const adminIdentityVerifications = '/admin/verifications/identity';

  static String adminApproveIdentityVerification(int id) =>
      '/admin/verifications/identity/$id/approve';

  static String adminRejectIdentityVerification(int id) =>
      '/admin/verifications/identity/$id/reject';

  static String adminApproveBooking(int id) => '/admin/bookings/$id/approve';

  static String adminRejectBooking(int id) => '/admin/bookings/$id/reject';

  static String adminStartBooking(int id) => '/admin/bookings/$id/start';

  static String adminCompleteBooking(int id) => '/admin/bookings/$id/complete';

  static String adminItemDetail(int id) => '/items/$id';

  static const adminCreateItem = '/admin/items';

  static String adminUpdateItem(int id) => '/admin/items/$id';

  static String adminDeleteItem(int id) => '/admin/items/$id';

  static String adminItemImages(int itemId) => '/admin/items/$itemId/images';

  static const adminDashboardSummary = '/admin/dashboard/summary';

  static const adminDashboardTopItems = '/admin/dashboard/top-items';

  static const adminDashboardRecentBookings =
      '/admin/dashboard/recent-bookings';

  static const adminDashboardBookingStatusDistribution =
      '/admin/dashboard/booking-status-distribution';

  static String adminUpdateUserRole(int id) => '/admin/users/$id/role';
}
