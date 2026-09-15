import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _selectedTab == 0 ? 0 : 1,
        children: [
          _HomeContent(onViewCourses: () => setState(() => _selectedTab = 1)),
          const _CoursesContent(),
        ],
      ),
    ),
    bottomNavigationBar: _BottomNavigation(
      selectedIndex: _selectedTab,
      onSelected: (index) => setState(() => _selectedTab = index),
    ),
  );
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onViewCourses});

  final VoidCallback onViewCourses;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: _WelcomeHeader()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const _ContinueWatchingCard(),
            const SizedBox(height: 24),
            _SectionHeading(
              title: 'My Courses',
              action: 'View All',
              onTap: onViewCourses,
            ),
            const SizedBox(height: 10),
            const _CourseCard(
              code: 'CS-401',
              title: 'Applied Cyber Security & Network Defense',
              progress: 0.65,
              remaining: '45 days left',
              color: Color(0xFF2A477B),
              videos: 12,
              documents: 3,
            ),
            const SizedBox(height: 14),
            const _CourseCard(
              code: 'DEV-204',
              title: 'Modern Application Development',
              progress: 0.32,
              remaining: 'Expiring soon',
              color: Color(0xFF455B77),
              videos: 18,
              documents: 5,
              expiring: true,
            ),
            const SizedBox(height: 14),
            const _CourseCard(
              code: 'DS-305',
              title: 'Data Structures & Algorithms',
              progress: 0.44,
              remaining: '72 days left',
              color: Color(0xFF385D61),
              videos: 20,
              documents: 8,
            ),
          ]),
        ),
      ),
    ],
  );
}

class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 13, 20, 28),
    decoration: const BoxDecoration(
      color: Color(0xFF1D3474),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 13,
              color: Color(0xFF9FB4E7),
            ),
            const SizedBox(width: 5),
            const Expanded(
              child: Text(
                'EDUTRUST\nACADEMY',
                style: TextStyle(
                  color: Color(0xFFC8D4F1),
                  fontSize: 10,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Notifications',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: TextStyle(color: Color(0xFFB7C5E3), fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Priya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3A9AD5),
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: const Text(
                'PS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDCE2EA)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C13254A),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 8, color: Color(0xFF268DCA)),
            const SizedBox(width: 6),
            const Text(
              'CONTINUE\nWATCHING',
              style: TextStyle(
                color: Color(0xFF61708A),
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Quick Play',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF268DCA),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 100,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF8F9297),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: Color(0xFF1D3474),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Module 4: Binary Trees & Graphs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF253A65),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Data Structures & Algorithms',
                    style: TextStyle(color: Color(0xFF67748A), fontSize: 11),
                  ),
                  SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: 0.44,
                    minHeight: 4,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    color: Color(0xFF258DC5),
                    backgroundColor: Color(0xFFE7EBF1),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Resume from 18:35',
                    style: TextStyle(
                      color: Color(0xFF258DC5),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E315F),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 10),
      const CircleAvatar(
        radius: 10,
        backgroundColor: Color(0xFFE5EAF3),
        child: Text(
          '3',
          style: TextStyle(
            color: Color(0xFF334B78),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const Spacer(),
      TextButton(
        onPressed: onTap,
        child: Text(
          action,
          style: const TextStyle(
            color: Color(0xFF277BA8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.code,
    required this.title,
    required this.progress,
    required this.remaining,
    required this.color,
    required this.videos,
    required this.documents,
    this.expiring = false,
  });
  final String code;
  final String title;
  final double progress;
  final String remaining;
  final Color color;
  final int videos;
  final int documents;
  final bool expiring;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDCE2EA)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C13254A),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                color: const Color(0xFFD1D3D5),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 26,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (expiring)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1A914),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Expiring\nSoon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF263B63),
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.videocam_outlined,
                    size: 14,
                    color: Color(0xFF497497),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$videos videos',
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: Color(0xFF497497),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$documents documents',
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}%\ncompleted',
                    style: const TextStyle(
                      color: Color(0xFF53647B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      color: const Color(0xFF2A91C7),
                      backgroundColor: const Color(0xFFE5EAF0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: expiring
                          ? const Color(0xFFFFF4DD)
                          : const Color(0xFFE9FAF3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      remaining,
                      style: TextStyle(
                        color: expiring
                            ? const Color(0xFFBD7A00)
                            : const Color(0xFF2F9A70),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CoursesContent extends StatelessWidget {
  const _CoursesContent();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'All Courses',
      style: TextStyle(
        color: Color(0xFF1E315F),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: selectedIndex > 1 ? 0 : selectedIndex,
    onTap: onSelected,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xFF1D3474),
    unselectedItemColor: const Color(0xFF8290A4),
    selectedFontSize: 10,
    unselectedFontSize: 10,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        activeIcon: Icon(Icons.menu_book),
        label: 'Courses',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.video_library_outlined),
        activeIcon: Icon(Icons.video_library),
        label: 'Live',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
  );
}
