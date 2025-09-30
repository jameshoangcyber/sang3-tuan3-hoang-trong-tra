import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class CameraTranslateScreen extends StatefulWidget {
  const CameraTranslateScreen({super.key});

  @override
  CameraTranslateScreenState createState() => CameraTranslateScreenState();
}

class CameraTranslateScreenState extends State<CameraTranslateScreen> {
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
    // Không cần khởi tạo camera nữa, chỉ cần kiểm tra quyền
    _checkPermissions();
    _checkCameraAvailability();
  }

  Future<void> _checkCameraAvailability() async {
    try {
      // Kiểm tra xem có camera nào khả dụng không
      await _imagePicker
          .pickImage(
            source: ImageSource.camera,
            imageQuality: 1,
            maxWidth: 1,
            maxHeight: 1,
          )
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      debugPrint('Camera availability check completed');
    } catch (e) {
      debugPrint('Camera may not be available: $e');
    }
  }

  Future<void> _checkPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        _showErrorDialog('Camera permission is required');
        return;
      }

      // Request storage permission for gallery (compatible with both old and new Android)
      bool storageGranted = await _requestStoragePermission();

      if (!storageGranted) {
        _showErrorDialog(
          'Storage permission is required for gallery access. Please grant permission in settings.',
          showSettingsButton: true,
        );
        return;
      }

      debugPrint('All permissions granted successfully');
    } catch (e) {
      debugPrint('Permission error: $e');
      _showErrorDialog('Failed to get permissions: $e');
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      // Try photos permission first (Android 13+)
      try {
        final photosStatus = await Permission.photos.request();
        debugPrint('Photos permission status: $photosStatus');
        if (photosStatus == PermissionStatus.granted) {
          return true;
        }
      } catch (e) {
        debugPrint('Photos permission not available: $e');
      }

      // Try storage permission (older Android versions)
      try {
        final storageStatus = await Permission.storage.request();
        debugPrint('Storage permission status: $storageStatus');
        if (storageStatus == PermissionStatus.granted) {
          return true;
        }
      } catch (e) {
        debugPrint('Storage permission not available: $e');
      }

      // Try external storage permission (very old Android versions)
      try {
        final externalStorageStatus = await Permission.manageExternalStorage
            .request();
        debugPrint(
          'External storage permission status: $externalStorageStatus',
        );
        if (externalStorageStatus == PermissionStatus.granted) {
          return true;
        }
      } catch (e) {
        debugPrint('External storage permission not available: $e');
      }

      // Fallback: try to check if we already have permission
      try {
        if (await Permission.storage.isGranted) {
          debugPrint('Storage permission already granted');
          return true;
        }
      } catch (e) {
        debugPrint('Cannot check storage permission: $e');
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  Future<void> _captureFromCamera() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Check camera permission first
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus != PermissionStatus.granted) {
        final requestStatus = await Permission.camera.request();
        if (requestStatus != PermissionStatus.granted) {
          _showErrorDialog('Camera permission is required to take photos.');
          return;
        }
      }

      debugPrint('Attempting to capture image from camera...');

      // Capture image từ camera bằng image_picker với timeout
      final XFile? image = await _imagePicker
          .pickImage(
            source: ImageSource.camera,
            imageQuality: 70, // Giảm chất lượng để tránh crash
            maxWidth: 1280, // Giảm kích thước để tránh crash
            maxHeight: 720,
            preferredCameraDevice: CameraDevice.rear, // Ưu tiên camera sau
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Camera timeout - camera may not be available');
            },
          );

      if (image != null) {
        debugPrint('Image captured successfully: ${image.path}');
        // Process the captured image
        await _processImageFile(image.path);
      } else {
        debugPrint('No image captured - user cancelled or camera failed');
        _showErrorDialog(
          'No image was captured. Please try again or use gallery instead.',
        );
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      String errorMessage = 'Failed to capture image: $e';

      // Provide specific error messages for common issues
      if (e.toString().contains('timeout') || e.toString().contains('Camera')) {
        errorMessage =
            'Camera is not available or not working properly. This is common in emulators. Please use the gallery option instead.';
      } else if (e.toString().contains('permission')) {
        errorMessage =
            'Camera permission is required. Please grant permission in settings.';
      }

      _showErrorDialog(
        errorMessage,
        showSettingsButton: e.toString().contains('permission'),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImageFile(String imagePath) async {
    try {
      debugPrint('Processing image: $imagePath');

      final inputImage = InputImage.fromFilePath(imagePath);

      // Recognize text với timeout
      final recognizedText = await _textRecognizer
          .processImage(inputImage)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Text recognition timeout');
            },
          );

      debugPrint('Text recognized: ${recognizedText.text}');

      if (recognizedText.text.isNotEmpty) {
        setState(() {
          _recognizedText = recognizedText.text;
        });

        // Translate text
        await _translateText(recognizedText.text);
      } else {
        setState(() {
          _recognizedText = 'Không tìm thấy text trong ảnh';
          _translatedText = '';
        });
        _showErrorDialog(
          'Không tìm thấy text trong ảnh. Vui lòng thử lại với ảnh khác.',
        );
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      setState(() {
        _recognizedText = 'Lỗi xử lý ảnh';
        _translatedText = '';
      });
      _showErrorDialog('Failed to process image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Check permissions again before picking image
      await _checkPermissions();

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

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
      debugPrint('Error picking image: $e');
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        _showErrorDialog(
          'Permission denied. Please grant storage permission in app settings.',
          showSettingsButton: true,
        );
      } else {
        _showErrorDialog('Failed to pick image: $e');
      }
    }
  }

  Future<void> _translateText(String text) async {
    try {
      debugPrint('Translating text: $text to $_targetLanguage');

      final translation = await _translator
          .translate(text, to: _targetLanguage)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Translation timeout');
            },
          );

      debugPrint('Translation result: ${translation.text}');

      setState(() {
        _translatedText = translation.text;
      });
    } catch (e) {
      debugPrint('Translation error: $e');
      setState(() {
        _translatedText = 'Lỗi dịch thuật';
      });
      _showErrorDialog('Translation failed: $e');
    }
  }

  void _showErrorDialog(String message, {bool showSettingsButton = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          if (showSettingsButton) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Mở Settings'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Translate'),
        backgroundColor: Colors.deepOrange,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String language) {
              setState(() {
                _targetLanguage = language;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'ja', child: Text('日本語')),
              const PopupMenuItem(value: 'ko', child: Text('한국어')),
              const PopupMenuItem(value: 'zh', child: Text('中文')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.camera_alt, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'Dịch thuật từ ảnh',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Chụp ảnh hoặc chọn từ thư viện để dịch text',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✨ Hỗ trợ dịch thuật từ ảnh',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Thư viện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                // Capture button
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _captureFromCamera,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_isProcessing ? 'Đang xử lý...' : 'Chụp ảnh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isProcessing
                            ? Colors.grey
                            : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Clear button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _recognizedText = '';
                      _translatedText = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Xóa kết quả'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Translation results
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.translate,
                          color: Colors.deepOrange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Kết quả dịch thuật',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recognized text
                          if (_recognizedText.isNotEmpty) ...[
                            const Text(
                              'Text gốc:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _recognizedText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Translated text
                          if (_translatedText.isNotEmpty) ...[
                            const Text(
                              'Bản dịch:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.deepOrange.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                _translatedText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],

                          // Empty state
                          if (_recognizedText.isEmpty &&
                              _translatedText.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Chụp ảnh hoặc chọn ảnh để dịch text',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Sử dụng camera hoặc thư viện ảnh',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
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
            ),
          ),
        ],
      ),
    );
  }
}
