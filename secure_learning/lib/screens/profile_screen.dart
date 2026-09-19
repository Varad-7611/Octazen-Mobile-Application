import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_api.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Timer? _timer;
  Map<String, dynamic>? _studentData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _studentData = AuthApi.cachedStudent;
    _fetchProfile();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchProfile(isPolling: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProfile({bool isPolling = false}) async {
    try {
      final response = await AuthApi.getProfile();
      if (!mounted) return;
      if (response['student'] != null) {
        setState(() {
          _studentData = response['student'] as Map<String, dynamic>;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!isPolling && _studentData == null) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'ST';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _handleLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deauthorize Session'),
        content: const Text(
          'Are you sure you want to log out from this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AuthApi.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _studentData?['fullName'] as String? ?? 'Priya Deshmukh';
    final rawUsername =
        _studentData?['username'] as String? ?? 'priya.deshmukh';
    final username = rawUsername.startsWith('@')
        ? rawUsername
        : '@$rawUsername';
    final rawId = _studentData?['id'];
    final studentIdStr = rawId != null ? 'STU${rawId.toString()}' : 'STU4821';
    final initials = _getInitials(fullName);

    if (_loading && _studentData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF162544),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null && _studentData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF162544),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _fetchProfile();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF162544),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Navy Banner Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    // Top App Header & Verified Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: Color(0xFF8FA3D0),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EDUTRUST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'ACADEMY',
                              style: TextStyle(
                                color: Color(0xFF90A4D4),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: Color(0xFF22C55E),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Device Verified',
                                style: TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Avatar Circle with Initials & Checkmark Badge
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF478EE8), Color(0xFF1E5BB5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Full Name
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Username & STU ID
                    Text(
                      '$username · $studentIdStr',
                      style: const TextStyle(
                        color: Color(0xFF9FB2D9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // White Content Sheet
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header: My Courses
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'My Courses',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            '3 Enrolled',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Enrolled Course Card 1
                    const _CourseDetailCard(
                      code: 'CS-401',
                      category: 'Core Curriculum',
                      daysLeft: '45 days left',
                      daysLeftColor: Color(0xFF16A34A),
                      daysLeftBg: Color(0xFFDCFCE7),
                      title: 'Applied Cyber Security & Network Defense',
                      validity: 'Nov 15, 2025',
                      progressText: 'Progress: 8/12 Modules',
                      percent: 65,
                      progressColor: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),

                    // Enrolled Course Card 2
                    const _CourseDetailCard(
                      code: 'CS-408',
                      category: 'Advanced Lab',
                      daysLeft: '80 days left',
                      daysLeftColor: Color(0xFF16A34A),
                      daysLeftBg: Color(0xFFDCFCE7),
                      title: 'Ethical Hacking & Vulnerability Assessment',
                      validity: 'Dec 20, 2025',
                      progressText: 'Progress: 3/10 Modules',
                      percent: 30,
                      progressColor: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),

                    // Enrolled Course Card 3
                    const _CourseDetailCard(
                      code: 'DEV-204',
                      category: 'Certificate Course',
                      daysLeft: '5 days left',
                      daysLeftColor: Color(0xFFD97706),
                      daysLeftBg: Color(0xFFFEF3C7),
                      title: 'Cloud Security Fundamentals & IAM',
                      validity: 'Oct 05, 2025',
                      progressText: 'Progress: 9/10 Modules',
                      percent: 90,
                      progressColor: Color(0xFFD97706),
                    ),
                    const SizedBox(height: 24),

                    // Settings Options Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _OptionRow(
                            icon: Icons.lock_outline,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            title: 'Change Password',
                            subtitle:
                                'Update institutional access PIN or password',
                            onTap: () {},
                          ),
                          const Divider(
                            height: 1,
                            indent: 64,
                            endIndent: 16,
                            color: Color(0xFFF1F5F9),
                          ),
                          _OptionRow(
                            icon: Icons.phone_outlined,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            title: 'Contact Institute',
                            subtitle: 'Reach academic helpdesk & administrator',
                            onTap: () {},
                          ),
                          const Divider(
                            height: 1,
                            indent: 64,
                            endIndent: 16,
                            color: Color(0xFFF1F5F9),
                          ),
                          _OptionRow(
                            icon: Icons.info_outline,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            title: 'About',
                            subtitle:
                                'Version 3.4.2 · Terms & privacy compliance',
                            onTap: () {},
                          ),
                          const Divider(
                            height: 1,
                            indent: 64,
                            endIndent: 16,
                            color: Color(0xFFF1F5F9),
                          ),
                          _OptionRow(
                            icon: Icons.logout,
                            iconBg: const Color(0xFFFEF2F2),
                            iconColor: const Color(0xFFEF4444),
                            title: 'Logout',
                            titleColor: const Color(0xFFEF4444),
                            subtitle:
                                'Deauthorize institutional session on this device',
                            subtitleColor: const Color(0xFFF87171),
                            onTap: _handleLogout,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Knox Security Footer
                    Center(
                      child: Column(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Protected institutional device session · EduTrust Knox 3.2',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Powered by Octazen Technologies LLP',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseDetailCard extends StatelessWidget {
  const _CourseDetailCard({
    required this.code,
    required this.category,
    required this.daysLeft,
    required this.daysLeftColor,
    required this.daysLeftBg,
    required this.title,
    required this.validity,
    required this.progressText,
    required this.percent,
    required this.progressColor,
  });

  final String code;
  final String category;
  final String daysLeft;
  final Color daysLeftColor;
  final Color daysLeftBg;
  final String title;
  final String validity;
  final String progressText;
  final int percent;
  final Color progressColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$code  $category',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: daysLeftBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: daysLeftColor),
                  const SizedBox(width: 5),
                  Text(
                    daysLeft,
                    style: TextStyle(
                      color: daysLeftColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Title
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),

        // Validity Date
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              'Valid until: $validity',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress Text and Percentage
        Row(
          children: [
            Text(
              progressText,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: TextStyle(
                color: progressColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Linear Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.subtitleColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor ?? const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
        ],
      ),
    ),
  );
}
