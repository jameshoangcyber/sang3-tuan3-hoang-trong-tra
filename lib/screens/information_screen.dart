import 'package:flutter/material.dart';
import 'package:sang3_tuan3_hoang_trong_tra/screens/information_screen.dart';
import 'temperature_screen.dart';
import 'unit_converter_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng dụng chuyển đổi'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TemperatureConverterScreen(),
                  ),
                );
              },
              child: const Text('Chuyển đổi nhiệt độ'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UnitConverterScreen(),
                  ),
                );
              },
              child: const Text('Chuyển đổi đơn vị đo'),
            ),
            // Hiển thị ảnh từ thư mục assets
            Image.asset(
              'images/school.png', // Đường dẫn tới ảnh trong thư mục assets
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            // Hiển thị ảnh từ Internet
            Image.network(
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSGQr4vSTzTPnM6JMqYxvsP9xS8wSvjcw8kMw&s', // URL ảnh
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}
