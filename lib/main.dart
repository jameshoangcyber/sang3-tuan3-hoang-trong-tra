import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Ứng dụng đa chức năng',
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
    ),
  );
}
