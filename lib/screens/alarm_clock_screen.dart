import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class AlarmClockScreen extends StatefulWidget {
  const AlarmClockScreen({super.key});

  @override
  AlarmClockScreenState createState() => AlarmClockScreenState();
}

class AlarmClockScreenState extends State<AlarmClockScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAlarmSet = false;
  bool _isAlarmPlaying = false;
  Timer? _alarmTimer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _alarmTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _setAlarm() {
    if (_isAlarmSet) {
      _cancelAlarm();
    } else {
      _scheduleAlarm();
    }
  }

  void _scheduleAlarm() {
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Nếu thời gian đã qua trong ngày, đặt cho ngày mai
    final targetTime = alarmTime.isBefore(now)
        ? alarmTime.add(Duration(days: 1))
        : alarmTime;

    final duration = targetTime.difference(now);

    _alarmTimer = Timer(duration, () {
      _playAlarm();
    });

    setState(() {
      _isAlarmSet = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Báo thức đã được đặt cho ${_selectedTime.format(context)}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelAlarm() {
    _alarmTimer?.cancel();
    _stopAlarm();

    setState(() {
      _isAlarmSet = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Báo thức đã được hủy'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _playAlarm() async {
    setState(() {
      _isAlarmPlaying = true;
    });

    // Phát âm thanh báo thức - sử dụng âm thanh hệ thống
    try {
      // Sử dụng âm thanh đơn giản từ URL công khai
      await _audioPlayer.play(
        UrlSource('https://www.soundjay.com/misc/sounds/bell-ringing-05.wav'),
      );
    } catch (e) {
      debugPrint('Không thể phát âm thanh từ URL: $e');
      // Fallback: sử dụng âm thanh hệ thống
      try {
        // Thử phát âm thanh từ asset
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      } catch (e2) {
        debugPrint('Không thể phát âm thanh từ asset: $e2');
        debugPrint('Báo thức đã kêu (chỉ có thông báo)');
      }
    }

    // Hiển thị thông báo
    await _showAlarmNotification();

    // Hiển thị dialog báo thức
    _showAlarmDialog();
  }

  Future<void> _showAlarmNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Notifications',
          channelDescription: 'Notifications for alarm clock',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notifications.show(
      0,
      'Báo thức!',
      'Đã đến giờ báo thức',
      platformChannelSpecifics,
    );
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Báo thức!'),
          content: Text(
            'Đã đến giờ báo thức: ${_selectedTime.format(context)}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _stopAlarm();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Tắt báo thức'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
    setState(() {
      _isAlarmPlaying = false;
      _isAlarmSet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đồng hồ báo thức'),
        backgroundColor: Colors.purple,
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
                    Icon(
                      Icons.alarm,
                      size: 80,
                      color: _isAlarmSet ? Colors.purple : Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Đồng hồ báo thức',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isAlarmSet
                          ? 'Báo thức đã được đặt'
                          : 'Chưa có báo thức nào',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isAlarmSet ? Colors.green : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'Thời gian báo thức',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, color: Colors.purple),
                          const SizedBox(width: 10),
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectTime,
                  icon: Icon(Icons.edit),
                  label: Text('Chọn giờ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _setAlarm,
                  icon: Icon(_isAlarmSet ? Icons.alarm_off : Icons.alarm),
                  label: Text(_isAlarmSet ? 'Hủy báo thức' : 'Đặt báo thức'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAlarmSet ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
            if (_isAlarmPlaying) ...[
              const SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.volume_up, size: 40, color: Colors.red),
                    const SizedBox(height: 10),
                    Text(
                      'Báo thức đang phát!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _stopAlarm,
                      icon: Icon(Icons.stop),
                      label: Text('Tắt báo thức'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
