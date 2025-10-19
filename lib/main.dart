import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    print("Error loading .env file: $e");
    // Continue without .env file
  }

  runApp(
    MaterialApp(
      title: 'Ứng dụng đa chức năng',
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
    ),
  );
}
