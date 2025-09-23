import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class VoiceControlScreen extends StatefulWidget {
  @override
  _VoiceControlScreenState createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends State<VoiceControlScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechEnabled = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _lastCommand = '';
  Timer? _timer;
  int _seconds = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _startListening() async {
    if (!_isListening) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            _processCommand(_recognizedText);
          });
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        localeId: "vi_VN",
        onSoundLevelChange: (level) {
          // Có thể thêm hiệu ứng âm thanh ở đây
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _processCommand(String command) {
    String lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('bắt đầu') || lowerCommand.contains('start')) {
      _startTimer();
      _speak('Đã bắt đầu bấm giờ');
    } else if (lowerCommand.contains('dừng') || lowerCommand.contains('stop')) {
      _stopTimer();
      _speak('Đã dừng bấm giờ');
    } else if (lowerCommand.contains('reset') ||
        lowerCommand.contains('đặt lại')) {
      _resetTimer();
      _speak('Đã đặt lại bấm giờ');
    } else if (lowerCommand.contains('xem thời gian') ||
        lowerCommand.contains('time')) {
      _speak('Thời gian hiện tại là ${_formatTime(_seconds)}');
    } else if (lowerCommand.contains('giúp') || lowerCommand.contains('help')) {
      _speak('Bạn có thể nói: bắt đầu, dừng, reset, xem thời gian');
    }

    _lastCommand = command;
  }

  void _startTimer() {
    if (!_isTimerRunning) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
      setState(() {
        _isTimerRunning = true;
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isTimerRunning = false;
    });
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điều khiển bằng giọng nói'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hiển thị thời gian
            Card(
              elevation: 8,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 60,
                      color: _isListening ? Colors.red : Colors.indigo,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Điều khiển bằng giọng nói',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.indigo, width: 2),
                      ),
                      child: Text(
                        _formatTime(_seconds),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Trạng thái nhận diện giọng nói
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isListening ? Colors.red[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isListening ? Colors.red : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _isListening ? 'Đang nghe...' : 'Sẵn sàng nghe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isListening ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_recognizedText.isNotEmpty) ...[
                    Text(
                      'Lệnh nhận diện:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _recognizedText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Các nút điều khiển
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _speechEnabled && !_isListening
                      ? _startListening
                      : null,
                  icon: Icon(Icons.mic),
                  label: Text('Bắt đầu nghe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isListening ? _stopListening : null,
                  icon: Icon(Icons.mic_off),
                  label: Text('Dừng nghe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Nút điều khiển thủ công
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTimerRunning ? null : _startTimer,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Bắt đầu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isTimerRunning ? _stopTimer : null,
                  icon: Icon(Icons.pause),
                  label: Text('Dừng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetTimer,
                  icon: Icon(Icons.refresh),
                  label: Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Hướng dẫn sử dụng
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hướng dẫn sử dụng:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• Nói "bắt đầu" hoặc "start" để bắt đầu bấm giờ\n'
                        '• Nói "dừng" hoặc "stop" để dừng bấm giờ\n'
                        '• Nói "reset" hoặc "đặt lại" để đặt lại thời gian\n'
                        '• Nói "xem thời gian" để nghe thời gian hiện tại\n'
                        '• Nói "giúp" để nghe lại hướng dẫn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
