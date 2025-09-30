import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class TeamInfoScreen extends StatefulWidget {
  const TeamInfoScreen({super.key});

  @override
  TeamInfoScreenState createState() => TeamInfoScreenState();
}

class TeamInfoScreenState extends State<TeamInfoScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _teamMembers = [
    {
      'name': 'VŨ ĐỨC ANH',
      'role': 'Leader',
      'studentId': '2280600140',
      'class': 'Sáng 3 - Tuần 4',
      'description':
          'Phát triển ứng dụng Flutter đa chức năng với các tính năng dịch thuật, nhận diện giọng nói và camera.',
      'skills': ['Flutter', 'Dart', 'Android', 'iOS', 'Firebase'],
      'avatar': 'images/avatar.png',
      'color': Colors.deepOrange,
    },
    {
      'name': 'TRẦN PHAN QUỐC ANH',
      'role': 'Developer',
      'studentId': '2280600124',
      'class': 'Sáng 3 - Tuần 4',
      'description': 'Hỗ trợ phát triển backend và tích hợp API cho ứng dụng.',
      'skills': ['Java', 'Spring Boot', 'MySQL', 'REST API'],
      'avatar': 'images/avatar_2.png',
      'color': Colors.blue,
    },
    {
      'name': 'HOÀNG TRỌNG TRÀ',
      'role': 'UI/UX Designer',
      'studentId': '2280603322',
      'class': 'Sáng 3 - Tuần 4',
      'description':
          'Thiết kế giao diện người dùng và trải nghiệm người dùng cho ứng dụng.',
      'skills': ['Figma', 'Adobe XD', 'UI Design', 'UX Research'],
      'avatar': 'images/avatar_3.png',
      'color': Colors.purple,
    },
    {
      'name': 'LÊ THÀNH NHƠN',
      'role': 'Tester',
      'studentId': '2280602244',
      'class': 'Sáng 3 - Tuần 4',
      'description': 'Kiểm thử ứng dụng và đảm bảo chất lượng sản phẩm.',
      'skills': ['Testing', 'QA', 'Automation', 'Bug Tracking'],
      'avatar': 'images/avatar_4.png',
      'color': Colors.green,
    },
    {
      'name': 'PHẠM TRẦN HƯNG BẢO',
      'role': 'Tester',
      'studentId': '2280600222',
      'class': 'Sáng 3 - Tuần 4',
      'description': 'Kiểm thử ứng dụng và đảm bảo chất lượng sản phẩm.',
      'skills': ['Testing', 'QA', 'Automation', 'Bug Tracking'],
      'avatar': 'images/avatar_5.png',
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
          child: Column(
            children: [
              _buildHeader(),
              _buildPageIndicator(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: _teamMembers.length,
                      itemBuilder: (context, index) {
                        return _buildMemberCard(_teamMembers[index]);
                      },
                    ),
                  ),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin nhóm',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Đội ngũ phát triển ứng dụng',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _teamMembers.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentIndex == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.arrow_back,
            label: 'Trước',
            onPressed: _currentIndex > 0
                ? () {
                    HapticFeedback.lightImpact();
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            isEnabled: _currentIndex > 0,
          ),
          _buildNavButton(
            icon: Icons.arrow_forward,
            label: 'Tiếp',
            onPressed: _currentIndex < _teamMembers.length - 1
                ? () {
                    HapticFeedback.lightImpact();
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            isEnabled: _currentIndex < _teamMembers.length - 1,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isEnabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with enhanced design
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      member['color'],
                      member['color'].withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: member['color'].withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    member['avatar'],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, size: 60, color: Colors.white);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Name with enhanced typography
              Text(
                member['name'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: member['color'],
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Role with modern design
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      member['color'],
                      member['color'].withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: member['color'].withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  member['role'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Student Info with modern card design
              _buildInfoCard(
                icon: Icons.badge,
                title: 'Thông tin sinh viên',
                children: [
                  _buildInfoRow(Icons.badge, 'MSSV', member['studentId']),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.class_, 'Lớp', member['class']),
                ],
                color: member['color'],
              ),

              const SizedBox(height: 16),

              // Description with modern card design
              _buildInfoCard(
                icon: Icons.description,
                title: 'Mô tả',
                children: [
                  Text(
                    member['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
                color: member['color'],
              ),

              const SizedBox(height: 16),

              // Skills with modern card design
              _buildInfoCard(
                icon: Icons.star,
                title: 'Kỹ năng',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (member['skills'] as List<String>).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              member['color'].withValues(alpha: 0.1),
                              member['color'].withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: member['color'].withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            color: member['color'],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                color: member['color'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}
