import 'package:flutter/material.dart';

class TemperatureConverterScreen extends StatefulWidget {
  const TemperatureConverterScreen({super.key});

  @override
  TemperatureConverterScreenState createState() =>
      TemperatureConverterScreenState();
}

class TemperatureConverterScreenState
    extends State<TemperatureConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  double? _convertedTemperature;
  bool _isCelsiusToFahrenheit = true;
  String _conversionType = 'Celsius → Fahrenheit';

  void _convertTemperature() {
    setState(() {
      final input = double.tryParse(_controller.text);
      if (input != null) {
        if (_isCelsiusToFahrenheit) {
          _convertedTemperature = input * 9 / 5 + 32; // C -> F
          _conversionType = 'Celsius → Fahrenheit';
        } else {
          _convertedTemperature = (input - 32) * 5 / 9; // F -> C
          _conversionType = 'Fahrenheit → Celsius';
        }
        _isCelsiusToFahrenheit = !_isCelsiusToFahrenheit;

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chuyển đổi thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng nhập số hợp lệ!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển đổi nhiệt độ'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.thermostat, size: 60, color: Colors.deepOrange),
                    const SizedBox(height: 20),
                    Text(
                      'Chuyển đổi nhiệt độ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _conversionType,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập nhiệt độ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                prefixIcon: Icon(Icons.input),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _convertedTemperature != null
                    ? Colors.green[50]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _convertedTemperature != null
                      ? Colors.green
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Text(
                _convertedTemperature == null
                    ? 'Kết quả sẽ hiển thị ở đây'
                    : '${_convertedTemperature!.toStringAsFixed(1)}°${_isCelsiusToFahrenheit ? 'F' : 'C'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _convertedTemperature != null
                      ? Colors.green[800]
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _convertTemperature,
        icon: Icon(Icons.swap_horiz),
        label: Text('Chuyển đổi'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}
