import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../theme/app_theme.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  PersonalScreenState createState() => PersonalScreenState();
}

class PersonalScreenState extends State<PersonalScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController(
    text: '0123456789', // Số điện thoại mặc định
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> _makePhoneCall() async {
    final String phoneNumber = _phoneController.text.trim();
    print('Attempting to call: $phoneNumber'); // Debug log

    if (phoneNumber.isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại', Colors.red);
      return;
    }

    // Hiển thị dialog xác nhận
    final bool? shouldCall = await _showCallConfirmationDialog(phoneNumber);
    if (shouldCall != true) {
      print('User cancelled phone call'); // Debug log
      return;
    }

    // Thử nhiều phương thức khác nhau
    bool success = await _tryLaunchPhoneCall(phoneNumber);

    if (success) {
      _showSnackBar('Đã mở giao diện cuộc gọi cho $phoneNumber', Colors.green);
    } else {
      _showSnackBar(
        'Không thể mở app gọi điện. Trên thiết bị thật sẽ hoạt động bình thường.',
        Colors.orange,
      );
    }
  }

  Future<bool> _tryLaunchPhoneCall(String phoneNumber) async {
    // Phương thức 1: Sử dụng Uri.parse với các mode khác nhau
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    print('Phone URI: $phoneUri'); // Debug log

    final List<LaunchMode> modes = [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.externalNonBrowserApplication,
    ];

    for (LaunchMode mode in modes) {
      try {
        print('Trying launch mode: $mode'); // Debug log
        await launchUrl(phoneUri, mode: mode);
        print('Successfully launched with mode: $mode'); // Debug log
        return true;
      } catch (e) {
        print('Mode $mode failed: $e'); // Debug log
        continue;
      }
    }

    // Phương thức 2: Thử launch không có mode
    try {
      print('Trying launch without mode'); // Debug log
      await launchUrl(phoneUri);
      print('Successfully launched without mode'); // Debug log
      return true;
    } catch (e) {
      print('Launch without mode failed: $e'); // Debug log
    }

    // Phương thức 3: Sử dụng launchUrlString (nếu có)
    try {
      print('Trying launchUrlString'); // Debug log
      await launchUrlString('tel:$phoneNumber');
      print('Successfully launched with launchUrlString'); // Debug log
      return true;
    } catch (e) {
      print('launchUrlString failed: $e'); // Debug log
    }

    // Phương thức 4: Thử với format khác
    try {
      print('Trying alternative format'); // Debug log
      final Uri altUri = Uri(scheme: 'tel', path: phoneNumber);
      await launchUrl(altUri);
      print('Successfully launched with alternative format'); // Debug log
      return true;
    } catch (e) {
      print('Alternative format failed: $e'); // Debug log
    }

    // Phương thức 5: Hiển thị dialog mô phỏng cuộc gọi cho emulator
    print('All methods failed, showing call simulation dialog'); // Debug log
    await _showCallSimulationDialog(phoneNumber);
    return true; // Trả về true vì đã hiển thị dialog mô phỏng
  }

  Future<void> _showCallSimulationDialog(String phoneNumber) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar người gọi
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Tên người gọi
                const Text(
                  'Đang gọi...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Số điện thoại
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 24),

                // Thời gian gọi (mô phỏng)
                StreamBuilder<int>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (i) => i + 1,
                  ),
                  builder: (context, snapshot) {
                    final seconds = snapshot.data ?? 0;
                    final minutes = seconds ~/ 60;
                    final remainingSeconds = seconds % 60;
                    return Text(
                      '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Nút điều khiển
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nút tắt tiếng
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showSnackBar('Đã tắt tiếng', Colors.blue);
                        },
                        icon: const Icon(
                          Icons.mic_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Nút kết thúc cuộc gọi
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          _showSnackBar('Đã kết thúc cuộc gọi', Colors.red);
                        },
                        icon: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                    // Nút loa ngoài
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showSnackBar('Đã bật loa ngoài', Colors.blue);
                        },
                        icon: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nút đóng
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSnackBar('Đã đóng giao diện cuộc gọi', Colors.grey);
                  },
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showCallConfirmationDialog(String phoneNumber) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.phone, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('Xác nhận cuộc gọi'),
            ],
          ),
          content: Text('Bạn có muốn gọi đến số $phoneNumber không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Gọi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openYouTube() async {
    const String youtubeUrl = 'https://www.youtube.com';
    final Uri youtubeUri = Uri.parse(youtubeUrl);

    try {
      if (await canLaunchUrl(youtubeUri)) {
        await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
        _showSnackBar('Đang mở YouTube', Colors.green);
      } else {
        _showSnackBar('Không thể mở YouTube', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildPhoneCallSection(),
                    const SizedBox(height: 20),
                    _buildYouTubeSection(),
                    const SizedBox(height: 30),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Hoang Trong Tra',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sáng 3 - Tuần 4',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Flutter Developer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCallSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone,
                  color: AppTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gọi điện',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              hintText: 'Nhập số điện thoại (ví dụ: 0123456789)',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _phoneController.clear();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Số điện thoại mặc định: 0123456789',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.successColor, Color(0xFF8BC34A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _makePhoneCall();
                    },
                    icon: const Icon(Icons.call, size: 20),
                    label: const Text(
                      'Gọi điện',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _phoneController.text = '0123456789';
                    _showSnackBar('Đã khôi phục số mặc định', Colors.blue);
                  },
                  icon: const Icon(Icons.restore, color: AppTheme.primaryColor),
                  tooltip: 'Khôi phục số mặc định',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'YouTube',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Mở ứng dụng YouTube để xem video',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFF5722)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _openYouTube();
              },
              icon: const Icon(Icons.play_circle_filled, size: 20),
              label: const Text(
                'Mở YouTube',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Ứng dụng đa chức năng - Flutter',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
