import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String get baseUrl {
    try {
      final url = dotenv.env['BASE_URL'];
      if (url != null && url.isNotEmpty) {
        return url;
      }
    } catch (e) {
      print("Error loading .env file: $e");
    }

    print("BASE_URL is not set in the .env file. Using default URL.");
    //đường dẫn API nếu không đọc được URL trong file .env
    return "https://192.168.1.228:45455/api/";
  }
}
