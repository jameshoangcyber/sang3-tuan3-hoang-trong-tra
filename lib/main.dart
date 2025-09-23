import 'package:flutter/material.dart';
import 'screens/HomeScreen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Ứng dụng đa chức năng',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    ),
  );
}
