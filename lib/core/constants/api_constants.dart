import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) return 'https://farmacare-api.onrender.com/api/v1';
    return 'http://10.0.2.2:3000/api/v1';
  }
}
