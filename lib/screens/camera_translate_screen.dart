import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraTranslateScreen extends StatefulWidget {
  @override
  _CameraTranslateScreenState createState() => _CameraTranslateScreenState();
}

class _CameraTranslateScreenState extends State<CameraTranslateScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _translatedText = '';
  String _targetLanguage = 'vi'; // Vietnamese
  final TextRecognizer _textRecognizer = TextRecognizer();
  final GoogleTranslator _translator = GoogleTranslator();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showErrorDialog('Camera permission is required');
      return;
    }

    // Get available cameras
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      _showErrorDialog('No cameras found');
      return;
    }

    // Initialize camera controller
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showErrorDialog('Failed to initialize camera: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      
      // Process the captured image
      await _processImageFile(image.path);
    } catch (e) {
      print('Error capturing image: $e');
      _showErrorDialog('Failed to capture image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImageFile(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Recognize text
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isNotEmpty) {
        setState(() {
          _recognizedText = recognizedText.text;
        });
        
        // Translate text
        await _translateText(recognizedText.text);
      } else {
        setState(() {
          _recognizedText = 'No text detected';
          _translatedText = '';
        });
      }
    } catch (e) {
      print('Error processing image: $e');
      _showErrorDialog('Failed to process image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _isProcessing = true;
        });
        
        await _processImageFile(image.path);
        
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _translateText(String text) async {
    try {
      final translation = await _translator.translate(text, to: _targetLanguage);
      setState(() {
        _translatedText = translation.text;
      });
    } catch (e) {
      print('Translation error: $e');
      _showErrorDialog('Translation failed: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Camera Translate'),
          backgroundColor: Colors.deepOrange,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Translate'),
        backgroundColor: Colors.deepOrange,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String language) {
              setState(() {
                _targetLanguage = language;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'ja', child: Text('日本語')),
              PopupMenuItem(value: 'ko', child: Text('한국어')),
              PopupMenuItem(value: 'zh', child: Text('中文')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child: CameraPreview(_cameraController!),
            ),
          ),
          
          // Control buttons
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.black.withOpacity(0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                FloatingActionButton(
                  onPressed: _pickImageFromGallery,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                
                // Capture button
                FloatingActionButton(
                  onPressed: _isProcessing ? null : _captureAndProcess,
                  backgroundColor: _isProcessing ? Colors.grey : Colors.red,
                  child: _isProcessing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.camera_alt, color: Colors.white),
                ),
                
                // Clear button
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _recognizedText = '';
                      _translatedText = '';
                    });
                  },
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.clear, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Translation results
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kết quả dịch:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  // Recognized text
                  if (_recognizedText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text gốc:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _recognizedText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Translated text
                  if (_translatedText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepOrange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bản dịch:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepOrange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _translatedText,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.deepOrange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Empty state
                  if (_recognizedText.isEmpty && _translatedText.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.translate,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Chụp ảnh hoặc chọn ảnh để dịch text',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
