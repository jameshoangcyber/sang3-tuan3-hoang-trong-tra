import 'package:flutter/material.dart';
import 'temperature_screen.dart';
import 'unit_converter_screen.dart';
import 'youtube_player_screen.dart';
import 'alarm_clock_screen.dart';
import 'stopwatch_screen.dart';
import 'voice_control_screen.dart';

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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header với ảnh
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.apps, size: 60, color: Colors.deepOrange),
                    const SizedBox(height: 20),
                    Text(
                      'Ứng dụng đa chức năng',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'HoangTrongTra - Sáng 3 Tuần 3',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Grid các chức năng
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context,
                  'Chuyển đổi nhiệt độ',
                  Icons.thermostat,
                  Colors.deepOrange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TemperatureConverterScreen(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'Chuyển đổi đơn vị',
                  Icons.straighten,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UnitConverterScreen(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'YouTube Player',
                  Icons.play_circle_filled,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YouTubePlayerScreen(),
                    ),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'Đồng hồ báo thức',
                  Icons.alarm,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AlarmClockScreen()),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'Đồng hồ bấm giờ',
                  Icons.timer,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StopwatchScreen()),
                  ),
                ),
                _buildFeatureCard(
                  context,
                  'Điều khiển giọng nói',
                  Icons.mic,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceControlScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Hiển thị ảnh
            Card(
              elevation: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'images/nxnja.jpg',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                            Text(
                              'Không thể tải ảnh',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
