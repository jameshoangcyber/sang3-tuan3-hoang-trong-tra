import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class VoiceAlarmScreen extends StatefulWidget {
  const VoiceAlarmScreen({super.key});

  @override
  VoiceAlarmScreenState createState() => VoiceAlarmScreenState();
}

class VoiceAlarmScreenState extends State<VoiceAlarmScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAlarmSet = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _statusMessage = 'Đang khởi tạo...';
  Timer? _alarmTimer;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Sound level for visual feedback
  double _soundLevel = 0.0;
  List<double> _soundLevels = List.generate(20, (index) => 0.0);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSpeech();
    _initTts();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _initSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _statusMessage = 'Cần quyền microphone để sử dụng tính năng này';
        });
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (errorNotification) {
          debugPrint('Speech recognition error: ${errorNotification.errorMsg}');
          if (mounted) {
            setState(() {
              _statusMessage = 'Lỗi: ${errorNotification.errorMsg}';
            });
          }
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (mounted) {
            setState(() {
              _statusMessage = 'Trạng thái: $status';
            });
          }
        },
      );

      setState(() {
        _statusMessage = _speechEnabled
            ? 'Sẵn sàng nghe'
            : 'Không thể khởi tạo nhận diện giọng nói';
      });
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      setState(() {
        _statusMessage = 'Lỗi khởi tạo: $e';
      });
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _startListening() async {
    if (!_isListening && _speechEnabled) {
      try {
        setState(() {
          _statusMessage = 'Đang nghe...';
        });

        // Start animations
        _pulseController.repeat(reverse: true);
        _waveController.repeat();

        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _statusMessage = 'Đã nhận diện: ${result.recognizedWords}';
            });

            // Update sound level for visual feedback
            if (result.recognizedWords.isNotEmpty) {
              _updateSoundLevel();
            }

            if (result.finalResult) {
              _processCommand(result.recognizedWords);
            }
          },
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 2),
          listenOptions: SpeechListenOptions(
            partialResults: true,
            cancelOnError: false,
            listenMode: ListenMode.dictation,
            enableHapticFeedback: true,
          ),
          localeId: "vi_VN",
          onSoundLevelChange: (level) {
            setState(() {
              _soundLevel = level;
            });
            _updateSoundLevel();
          },
        );
        setState(() {
          _isListening = true;
        });

        // Haptic feedback
        HapticFeedback.lightImpact();
      } catch (e) {
        debugPrint('Error starting listening: $e');
        setState(() {
          _statusMessage = 'Lỗi bắt đầu nghe: $e';
        });
      }
    }
  }

  void _updateSoundLevel() {
    setState(() {
      _soundLevels.removeAt(0);
      _soundLevels.add(_soundLevel);
    });
  }

  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
        _statusMessage = 'Đã dừng nghe';
      });

      // Stop animations
      _pulseController.stop();
      _waveController.stop();

      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _processCommand(String command) {
    String lowerCommand = command.toLowerCase().trim();

    // Stop listening after processing command
    _stopListening();

    // Xử lý lệnh hủy báo thức
    if (lowerCommand.contains('hủy báo thức') ||
        lowerCommand.contains('cancel alarm') ||
        lowerCommand.contains('tắt báo thức') ||
        lowerCommand.contains('dừng báo thức')) {
      _cancelAlarm();
      _speak('Đã hủy báo thức');
      return;
    }

    // Xử lý lệnh giúp đỡ
    if (lowerCommand.contains('giúp') ||
        lowerCommand.contains('help') ||
        lowerCommand.contains('hướng dẫn')) {
      _showHelpDialog();
      return;
    }

    // Xử lý lệnh thời gian
    if (lowerCommand.contains('thời gian') ||
        lowerCommand.contains('time') ||
        lowerCommand.contains('mấy giờ')) {
      _speakCurrentTime();
      return;
    }

    // Xử lý lệnh dừng
    if (lowerCommand.contains('dừng') ||
        lowerCommand.contains('stop') ||
        lowerCommand.contains('thôi')) {
      _speak('Đã dừng nghe');
      return;
    }

    // Xử lý lệnh đặt báo thức (bao gồm cả lệnh có thời gian cụ thể)
    if (lowerCommand.contains('đặt báo thức') ||
        lowerCommand.contains('set alarm') ||
        lowerCommand.contains('báo thức') ||
        lowerCommand.contains('alarm') ||
        _containsTimePattern(lowerCommand)) {
      _processAlarmCommand(command);
      return;
    }

    // Nếu không nhận diện được lệnh
    _speak('Tôi không hiểu lệnh này. Hãy nói "giúp" để xem hướng dẫn.');
  }

  bool _containsTimePattern(String text) {
    // Kiểm tra xem có chứa pattern thời gian không
    List<RegExp> timePatterns = [
      RegExp(r'\d{1,2}\s*(?:giờ|hour|h|:)\s*\d{1,2}\s*(?:phút|minute|m)?'),
      RegExp(r'\d{1,2}\s*(?:giờ|hour|h)(?!\s*\d)'),
      RegExp(r'\d{1,2}\s*(?:phút|minute|m)(?!\s*\d)'),
      RegExp(r'(sáng|chiều|tối)\s*\d{1,2}'),
      RegExp(r'\d{1,2}[:.]\d{1,2}'),
      RegExp(r'\d{1,2}h\d{1,2}m?'),
    ];

    return timePatterns.any((pattern) => pattern.hasMatch(text));
  }

  void _speakCurrentTime() {
    final now = TimeOfDay.now();
    _speak('Bây giờ là ${now.format(context)}');
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hướng dẫn sử dụng',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Các lệnh giọng nói được hỗ trợ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('• "Đặt báo thức" - Đặt báo thức mới'),
                Text('• "Hủy báo thức" - Hủy báo thức hiện tại'),
                Text('• "7 giờ 30 phút" - Đặt báo thức cho 7:30'),
                Text('• "Thời gian" - Nghe thời gian hiện tại'),
                Text('• "Giúp" - Hiển thị hướng dẫn này'),
                Text('• "Dừng" - Dừng nghe giọng nói'),
                SizedBox(height: 10),
                Text(
                  'Ví dụ: "Đặt báo thức 8 giờ 15 phút"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _speak(
                  'Bạn có thể nói: đặt báo thức, hủy báo thức, hoặc nói thời gian cụ thể',
                );
              },
              child: const Text('Nghe hướng dẫn'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _processAlarmCommand(String command) {
    String lowerCommand = command.toLowerCase();
    debugPrint('Processing alarm command: $lowerCommand');

    // Các regex patterns để nhận diện thời gian
    List<RegExp> timePatterns = [
      // "7 giờ 30 phút", "7h30", "7:30"
      RegExp(r'(\d{1,2})\s*(?:giờ|hour|h|:)\s*(\d{1,2})\s*(?:phút|minute|m)?'),
      // "7 giờ", "7h"
      RegExp(r'(\d{1,2})\s*(?:giờ|hour|h)(?!\s*\d)'),
      // "30 phút" (từ bây giờ)
      RegExp(r'(\d{1,2})\s*(?:phút|minute|m)(?!\s*\d)'),
      // "sáng", "chiều", "tối"
      RegExp(
        r'(sáng|chiều|tối)\s*(\d{1,2})\s*(?:giờ|hour|h)?\s*(\d{1,2})?\s*(?:phút|minute|m)?',
      ),
      // "7:30", "7.30"
      RegExp(r'(\d{1,2})[:.](\d{1,2})'),
      // "7h30", "7h30m"
      RegExp(r'(\d{1,2})h(\d{1,2})m?'),
    ];

    TimeOfDay? parsedTime;

    for (int i = 0; i < timePatterns.length; i++) {
      RegExp pattern = timePatterns[i];
      Match? match = pattern.firstMatch(lowerCommand);
      if (match != null) {
        debugPrint('Found time pattern $i: ${match.group(0)}');
        parsedTime = _parseTimeFromMatch(match, lowerCommand);
        if (parsedTime != null) {
          debugPrint('Parsed time: ${parsedTime.format(context)}');
          break;
        }
      }
    }

    if (parsedTime != null) {
      setState(() {
        _selectedTime = parsedTime!;
      });

      _scheduleAlarm();
      _speak('Đã đặt báo thức cho ${_selectedTime.format(context)}');
    } else {
      // Nếu không tìm thấy thời gian, sử dụng thời gian hiện tại + 5 phút
      final now = TimeOfDay.now();
      final nextMinute = now.minute + 5;
      final nextHour = nextMinute >= 60 ? now.hour + 1 : now.hour;

      setState(() {
        _selectedTime = TimeOfDay(
          hour: nextHour >= 24 ? 0 : nextHour,
          minute: nextMinute >= 60 ? 0 : nextMinute,
        );
      });

      _scheduleAlarm();
      _speak(
        'Đã đặt báo thức cho ${_selectedTime.format(context)} (5 phút nữa)',
      );
    }
  }

  TimeOfDay? _parseTimeFromMatch(Match match, String command) {
    try {
      int hour = 0;
      int minute = 0;

      debugPrint('Match groups: ${match.groups}');

      // Xử lý thời gian sáng/chiều/tối
      if (match.group(1) == 'sáng' ||
          match.group(1) == 'chiều' ||
          match.group(1) == 'tối') {
        String period = match.group(1)!;
        hour = int.tryParse(match.group(2) ?? '0') ?? 0;
        minute = int.tryParse(match.group(3) ?? '0') ?? 0;

        debugPrint('Period time: $period, hour: $hour, minute: $minute');

        // Chuyển đổi sang 24h format
        if (period == 'chiều' && hour < 12) hour += 12;
        if (period == 'tối' && hour < 12) hour += 12;
        if (period == 'sáng' && hour == 12) hour = 0;
      } else {
        // Xử lý thời gian thông thường
        hour = int.tryParse(match.group(1) ?? '0') ?? 0;
        minute = int.tryParse(match.group(2) ?? '0') ?? 0;

        debugPrint('Normal time: hour: $hour, minute: $minute');

        // Nếu chỉ có phút (không có giờ), thêm vào thời gian hiện tại
        if (command.contains('phút') &&
            !command.contains('giờ') &&
            !command.contains('h')) {
          final now = TimeOfDay.now();
          final totalMinutes = now.hour * 60 + now.minute + minute;
          hour = (totalMinutes ~/ 60) % 24;
          minute = totalMinutes % 60;
          debugPrint('Added minutes: hour: $hour, minute: $minute');
        }
      }

      // Validate time
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        debugPrint('Valid time: $hour:$minute');
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        debugPrint('Invalid time: $hour:$minute');
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }

    return null;
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
        ? alarmTime.add(const Duration(days: 1))
        : alarmTime;

    final duration = targetTime.difference(now);

    debugPrint('Scheduling alarm for: ${_selectedTime.format(context)}');
    debugPrint('Duration until alarm: ${duration.inMinutes} minutes');

    _alarmTimer = Timer(duration, () {
      _playAlarm();
    });

    setState(() {
      _isAlarmSet = true;
    });

    // Hiển thị thông báo với thời gian còn lại
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    String timeLeft = '';
    if (hours > 0) {
      timeLeft = ' (${hours}h ${minutes}m nữa)';
    } else {
      timeLeft = ' (${minutes}m nữa)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Báo thức đã được đặt cho ${_selectedTime.format(context)}$timeLeft',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
      const SnackBar(
        content: Text('Báo thức đã được hủy'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _playAlarm() async {
    setState(() {
      _isAlarmSet = true;
    });

    // Phát âm thanh báo thức
    try {
      await _audioPlayer.play(
        UrlSource('https://www.soundjay.com/misc/sounds/bell-ringing-05.wav'),
      );
    } catch (e) {
      debugPrint('Không thể phát âm thanh từ URL: $e');
      try {
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
          title: const Text('Báo thức!'),
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
              child: const Text('Tắt báo thức'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
    setState(() {
      _isAlarmSet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildVoiceStatusCard(),
                    const SizedBox(height: 30),
                    _buildControlButtons(),
                    const SizedBox(height: 30),
                    _buildAlarmTimeCard(),
                    const SizedBox(height: 30),
                    _buildHelpCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isAlarmSet ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isAlarmSet
                          ? [Colors.orange, Colors.red]
                          : [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isAlarmSet ? Colors.orange : Colors.white)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.alarm,
                    size: 50,
                    color: _isAlarmSet
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Báo thức bằng giọng nói',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _isAlarmSet ? 'Báo thức đã được đặt' : 'Chưa có báo thức nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sound level visualization
          if (_isListening) _buildSoundVisualizer(),

          const SizedBox(height: 20),

          // Status message
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isListening
                  ? Colors.red[100]
                  : Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Lệnh nhận diện:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoundVisualizer() {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _soundLevels.map((level) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: (level * 50).clamp(5.0, 50.0),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            onPressed: _speechEnabled && !_isListening
                ? _startListening
                : _stopListening,
            icon: _isListening ? Icons.mic_off : Icons.mic,
            label: _isListening ? 'Dừng nghe' : 'Bắt đầu nghe',
            color: _isListening ? Colors.red : Colors.green,
            isEnabled: _speechEnabled,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildControlButton(
            onPressed: _isAlarmSet ? _cancelAlarm : null,
            icon: _isAlarmSet ? Icons.alarm_off : Icons.alarm,
            label: _isAlarmSet ? 'Hủy báo thức' : 'Chưa có báo thức',
            color: _isAlarmSet ? Colors.red : Colors.grey,
            isEnabled: _isAlarmSet,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isEnabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAlarmTimeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Thời gian báo thức',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              _selectedTime.format(context),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Hướng dẫn sử dụng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '• "Đặt báo thức" - Đặt báo thức mới\n'
            '• "Hủy báo thức" - Hủy báo thức hiện tại\n'
            '• "7 giờ 30 phút" - Đặt báo thức cho 7:30\n'
            '• "30 phút" - Đặt báo thức sau 30 phút\n'
            '• "Sáng 8 giờ" - Đặt báo thức sáng 8h\n'
            '• "Thời gian" - Nghe thời gian hiện tại\n'
            '• "Giúp" - Hiển thị hướng dẫn\n'
            '• "Dừng" - Dừng nghe giọng nói',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Text(
              'Ví dụ: "Đặt báo thức 8 giờ 15 phút"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
