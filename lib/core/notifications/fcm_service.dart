// import 'dart:io';

// import 'package:firebase_messaging/firebase_messaging.dart';

// class FcmService {
//   final FirebaseMessaging _messaging;

//   const FcmService({FirebaseMessaging? messaging})
//     : _messaging = messaging ?? FirebaseMessaging.instance;

//   Future<String?> getToken() async {
//     final permission = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     final allowed =
//         permission.authorizationStatus == AuthorizationStatus.authorized ||
//         permission.authorizationStatus == AuthorizationStatus.provisional;

//     if (!allowed) {
//       return null;
//     }

//     return _messaging.getToken();
//   }

//   String get platform {
//     if (Platform.isAndroid) return 'android';
//     if (Platform.isIOS) return 'ios';
//     return Platform.operatingSystem;
//   }

//   String get deviceName {
//     if (Platform.isAndroid) return 'Android Phone';
//     if (Platform.isIOS) return 'iPhone';
//     return 'Unknown Device';
//   }

//   Stream<String> get onTokenRefresh {
//     return _messaging.onTokenRefresh;
//   }
// }
