# 📱 Ứng dụng đa chức năng Flutter

Ứng dụng Flutter đa chức năng với các tính năng dịch thuật, nhận diện giọng nói, camera, đồng hồ báo thức và nhiều tiện ích khác.

## ✨ Tính năng chính

- 🏠 **Trang chủ**: Giao diện chính với navigation đẹp mắt
- 🌐 **Dịch thuật**: Dịch text và dịch từ ảnh chụp
- 📞 **Cá nhân**: Gọi điện, mở YouTube
- 👥 **Thông tin nhóm**: Hiển thị thông tin thành viên
- ⏰ **Đồng hồ báo thức**: Thiết lập và quản lý báo thức
- 🎯 **Đồng hồ bấm giờ**: Stopwatch với giao diện hiện đại
- 🌡️ **Chuyển đổi nhiệt độ**: Chuyển đổi giữa các đơn vị nhiệt độ
- 🔄 **Chuyển đổi đơn vị**: Chuyển đổi các đơn vị đo lường
- 🎵 **Điều khiển giọng nói**: Điều khiển ứng dụng bằng giọng nói
- 📺 **YouTube Player**: Xem video YouTube trong ứng dụng

## 🚀 Cài đặt và Chạy dự án

### Yêu cầu hệ thống

- Flutter SDK (phiên bản 3.0 trở lên)
- Dart SDK
- Android Studio / VS Code
- Android SDK (API level 21 trở lên)
- Git

### 1. Clone dự án

```bash
git clone https://github.com/your-username/sang3-tuan3-hoang-trong-tra.git
cd sang3-tuan3-hoang-trong-tra
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình quyền Android

Mở file `android/app/src/main/AndroidManifest.xml` và đảm bảo có các quyền sau:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions for the app -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.MICROPHONE" />
    
    <!-- Camera permissions for text recognition and translation -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- Phone call permission -->
    <uses-permission android:name="android.permission.CALL_PHONE" />
    
    <!-- Alarm clock permissions -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
    
    <!-- Queries for external apps -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

### 4. Cấu hình Assets

Đảm bảo file `pubspec.yaml` có cấu hình assets:

```yaml
flutter:
  assets:
    - images/hutech.png
    - images/avatar.png
    - images/avatar_2.png
    - images/avatar_3.png
    - images/avatar_4.png
    - images/avatar_5.png
    - assets/sounds/
```

### 5. Chạy ứng dụng

```bash
# Chạy trên emulator/thiết bị
flutter run

# Chạy với hot reload
flutter run --hot

# Build APK
flutter build apk --release
```

## 📦 Dependencies chính

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI & Navigation
  cupertino_icons: ^1.0.2
  
  # Text to Speech
  flutter_tts: ^3.8.5
  
  # Speech Recognition
  speech_to_text: ^6.6.0
  
  # Local Notifications
  flutter_local_notifications: ^17.2.3
  
  # URL Launcher
  url_launcher: ^6.3.1
  
  # Camera functionality
  camera: ^0.10.5+9
  
  # Image processing and text recognition
  google_mlkit_text_recognition: ^0.11.0
  
  # Google Translate API
  translator: ^1.0.4+1
  
  # HTTP requests
  http: ^1.5.0
  
  # Permission handling
  permission_handler: ^11.3.1
  
  # Image picker
  image_picker: ^1.0.7
  
  # State management
  provider: ^6.1.1
```

## 🏗️ Cấu trúc dự án

```
lib/
├── main.dart                          # Entry point
├── theme/
│   └── app_theme.dart                 # Theme configuration
├── screens/
│   ├── main_navigation_screen.dart    # Main navigation
│   ├── home_screen.dart               # Home screen
│   ├── translate_screen.dart          # Text translation
│   ├── camera_translate_screen.dart   # Camera translation
│   ├── personal_screen.dart           # Personal features
│   ├── team_info_screen.dart          # Team information
│   ├── alarm_clock_screen.dart        # Alarm clock
│   ├── stopwatch_screen.dart          # Stopwatch
│   ├── temperature_screen.dart        # Temperature converter
│   ├── unit_converter_screen.dart     # Unit converter
│   ├── voice_control_screen.dart      # Voice control
│   ├── voice_alarm_screen.dart        # Voice alarm
│   ├── youtube_player_screen.dart     # YouTube player
│   ├── settings_screen.dart           # Settings
│   └── information_screen.dart        # App information
└── screens/
    └── navigation_state_manager.dart  # Navigation state management
```

## 🎨 Tính năng UI/UX

- **Modern Design**: Giao diện hiện đại với Material Design 3
- **Gradient Backgrounds**: Nền gradient đẹp mắt cho từng màn hình
- **Glassmorphism Effects**: Hiệu ứng kính mờ hiện đại
- **Smooth Animations**: Animation mượt mà với FadeTransition và SlideTransition
- **Responsive Layout**: Giao diện responsive trên mọi kích thước màn hình
- **Dark/Light Theme**: Hỗ trợ theme sáng/tối
- **Haptic Feedback**: Phản hồi rung khi tương tác

## 🔧 Troubleshooting

### Lỗi thường gặp

1. **Camera không hoạt động**:
   - Kiểm tra quyền CAMERA trong AndroidManifest.xml
   - Đảm bảo emulator có camera

2. **Gọi điện không hoạt động**:
   - Emulator không có app gọi điện mặc định
   - Trên thiết bị thật sẽ hoạt động bình thường

3. **Text recognition lỗi**:
   - Kiểm tra kết nối internet
   - Đảm bảo ảnh có text rõ ràng

4. **Speech recognition không hoạt động**:
   - Kiểm tra quyền MICROPHONE
   - Đảm bảo có kết nối internet

### Debug

```bash
# Xem logs chi tiết
flutter logs

# Kiểm tra devices
flutter devices

# Clean và rebuild
flutter clean
flutter pub get
flutter run
```

## 👥 Thành viên nhóm

- **VŨ ĐỨC ANH** - Leader (2280600140)
- **TRẦN PHAN QUỐC ANH** - Developer (2280603322)  
- **HOÀNG TRỌNG TRÀ** - UI/UX Designer (2280600124)
- **LÊ THÀNH NHƠN** - Tester (2280602244)
- **PHẠM TRẦN HƯNG BẢO** - Tester (2280600222)

## 📄 License

Dự án này được phát triển cho mục đích học tập và nghiên cứu.

## 🤝 Đóng góp

1. Fork dự án
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📞 Liên hệ

Nếu có vấn đề hoặc câu hỏi, vui lòng tạo issue trên GitHub hoặc liên hệ team.

---

**Lưu ý**: Dự án này được phát triển trên Flutter với mục đích học tập. Một số tính năng có thể cần thiết bị thật để hoạt động đầy đủ (như gọi điện, camera).
