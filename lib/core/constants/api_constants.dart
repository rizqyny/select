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
  static const adminItems = '/admin/items';
  static const adminIdentityVerifications = '/admin/verifications/identity';

  static String adminApproveIdentityVerification(int id) =>
      '/admin/verifications/identity/$id/approve';

  static String adminRejectIdentityVerification(int id) =>
      '/admin/verifications/identity/$id/reject';
}
