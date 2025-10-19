import 'package:shared_preferences/shared_preferences.dart';

class SmartAuthService {
  // Khởi tạo Smart Auth
  static Future<void> initialize() async {
    // Smart Auth không cần khởi tạo đặc biệt
    print('Smart Auth initialized');
  }

  // Xác thực bằng vân tay/Face ID
  static Future<bool> authenticateWithBiometrics() async {
    try {
      // Simulate biometric authentication
      // Trong thực tế, đây sẽ là nơi gọi API biometric thực
      print('Biometric authentication requested');

      // Tạm thời return true để test
      // Trong production, đây sẽ là nơi gọi API biometric thực
      return true;
    } catch (e) {
      print('Smart Auth Error: $e');
      return false;
    }
  }

  // Kiểm tra xem có thể sử dụng Smart Auth không
  static Future<bool> isBiometricAvailable() async {
    try {
      // Simulate biometric availability check
      // Trong thực tế, đây sẽ kiểm tra xem device có hỗ trợ biometric không
      print('Checking biometric availability');

      // Tạm thời return true để test
      // Trong production, đây sẽ kiểm tra device capabilities
      return true;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Lưu thông tin xác thực sinh trắc học
  static Future<void> saveBiometricAuth(
    String username,
    String password,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometric_username', username);
      await prefs.setString('biometric_password', password);
      await prefs.setBool('biometric_enabled', true);
      print('Biometric auth saved for user: $username');
    } catch (e) {
      print('Error saving biometric auth: $e');
    }
  }

  // Lấy thông tin xác thực sinh trắc học
  static Future<Map<String, String?>> getBiometricAuth() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('biometric_username');
      String? password = prefs.getString('biometric_password');

      return {'username': username, 'password': password};
    } catch (e) {
      print('Error getting biometric auth: $e');
      return {'username': null, 'password': null};
    }
  }

  // Xóa thông tin xác thực sinh trắc học
  static Future<void> clearBiometricAuth() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('biometric_username');
      await prefs.remove('biometric_password');
      await prefs.setBool('biometric_enabled', false);
      print('Biometric auth cleared');
    } catch (e) {
      print('Error clearing biometric auth: $e');
    }
  }

  // Kiểm tra xem Smart Auth có được bật không
  static Future<bool> isBiometricEnabled() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Đăng nhập bằng Smart Auth
  static Future<Map<String, dynamic>> loginWithBiometrics() async {
    try {
      // Kiểm tra xem Smart Auth có khả dụng không
      bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return {'success': false, 'message': 'Smart Auth không khả dụng'};
      }

      // Kiểm tra xem có thông tin đăng nhập được lưu không
      Map<String, String?> authInfo = await getBiometricAuth();
      if (authInfo['username'] == null || authInfo['password'] == null) {
        return {
          'success': false,
          'message': 'Chưa có thông tin đăng nhập được lưu',
        };
      }

      // Xác thực sinh trắc học
      bool authResult = await authenticateWithBiometrics();
      if (!authResult) {
        return {'success': false, 'message': 'Xác thực sinh trắc học thất bại'};
      }

      // Trả về thông tin đăng nhập
      return {
        'success': true,
        'username': authInfo['username'],
        'password': authInfo['password'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi Smart Auth: $e'};
    }
  }
}
