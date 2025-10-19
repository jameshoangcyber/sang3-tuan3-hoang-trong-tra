import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class AuthService {
  // đường dẫn tới API login
  String get apiUrl => "${ConfigUrl.baseUrl}Authenticate/login";

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print("Login URL: $apiUrl");
      print("Username: $username");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        //Lấy thông tin tên đăng nhập và password
        body: jsonEncode({"username": username, "password": password}),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("API Response: $data");
        bool status = data['status'] ?? false;
        if (!status) {
          return {
            "success": false,
            "message": data['message'] ?? "Login failed",
          };
        }
        //lấy token trả về
        String? token = data['token'];
        if (token == null || token.isEmpty) {
          return {"success": false, "message": "No token received"};
        }
        // Decode token để lấy các thông tin đăng nhập: tên đăng nhập, role...
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

        // Lưu token vào SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', token); // Lưu token

        return {"success": true, "token": token, "decodedToken": decodedToken};
      } else {
        // If status code is not 200, treat it as login failure
        return {
          "success": false,
          "message": "Failed to login: ${response.statusCode}",
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
