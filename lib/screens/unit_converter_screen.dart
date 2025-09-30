import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  UnitConverterScreenState createState() => UnitConverterScreenState();
}

class UnitConverterScreenState extends State<UnitConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  double? _convertedValue;
  bool _isMetersToFeet = true;
  String _conversionType = 'Mét → Feet';

  void _convertUnits() {
    setState(() {
      final input = double.tryParse(_controller.text);
      if (input != null) {
        if (_isMetersToFeet) {
          _convertedValue = input * 3.28084; // M -> Ft
          _conversionType = 'Mét → Feet';
        } else {
          _convertedValue = input / 3.28084; // Ft -> M
          _conversionType = 'Feet → Mét';
        }
        _isMetersToFeet = !_isMetersToFeet;

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
        title: const Text('Chuyển đổi đơn vị đo'),
        backgroundColor: Colors.blue,
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
                    Icon(Icons.straighten, size: 60, color: Colors.blue),
                    const SizedBox(height: 20),
                    Text(
                      'Chuyển đổi đơn vị đo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
                hintText: 'Nhập giá trị',
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
                color: _convertedValue != null
                    ? Colors.green[50]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _convertedValue != null ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Text(
                _convertedValue == null
                    ? 'Kết quả sẽ hiển thị ở đây'
                    : '${_convertedValue!.toStringAsFixed(2)} ${_isMetersToFeet ? 'ft' : 'm'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _convertedValue != null
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
        onPressed: _convertUnits,
        icon: Icon(Icons.swap_horiz),
        label: Text('Chuyển đổi'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
