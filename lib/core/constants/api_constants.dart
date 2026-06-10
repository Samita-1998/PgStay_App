import 'dart:io';

class ApiConstants {
  // Use 10.0.2.2 for Android emulator to access localhost, otherwise use localhost
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://pg-backend-l3q4.onrender.com';
    }
    return 'https://pg-backend-l3q4.onrender.com';
  }
}
