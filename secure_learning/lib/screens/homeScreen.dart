import 'package:flutter/material.dart';
import '../services/auth_api.dart';
import '../services/courses_api.dart';
import 'profile_screen.dart';
import 'student_course_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  final GlobalKey<_HomeContentState> _homeKey = GlobalKey<_HomeContentState>();

  void _onCourseEnrolled() {
    _homeKey.currentState?.refreshEnrolled();
    setState(() {});
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
    if (index == 0) {
      _homeKey.currentState?.refreshEnrolled();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _selectedTab,
        children: [
          _HomeContent(
            key: _homeKey,
            onViewCourses: () => _onTabSelected(1),
            onViewProfile: () => _onTabSelected(3),
          ),
          _CoursesContent(onEnrolled: _onCourseEnrolled),
          const _LiveContent(),
          const ProfileScreen(),
        ],
      ),
    ),
    bottomNavigationBar: _BottomNavigation(
      selectedIndex: _selectedTab,
      onSelected: _onTabSelected,
    ),
  );
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    super.key,
    required this.onViewCourses,
    required this.onViewProfile,
  });

  final VoidCallback onViewCourses;
  final VoidCallback onViewProfile;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  late Future<List<CourseItem>> _enrolledFuture;

  @override
  void initState() {
    super.initState();
    refreshEnrolled();
  }

  void refreshEnrolled() {
    setState(() {
      _enrolledFuture = CoursesApi.fetchEnrolledCourses();
    });
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: _WelcomeHeader(onProfileTap: widget.onViewProfile),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            FutureBuilder<List<CourseItem>>(
              future: _enrolledFuture,
              builder: (context, snapshot) {
                final enrolled = snapshot.data ?? [];
                CourseVideo? activeVideo;
                CourseItem? activeCourse;

                if (enrolled.isNotEmpty) {
                  activeCourse = enrolled.first;
                  if (activeCourse.videos.isNotEmpty) {
                    activeVideo = activeCourse.videos.firstWhere(
                      (v) => !v.isCompleted && v.watchedSeconds > 0,
                      orElse: () => activeCourse!.videos.first,
                    );
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContinueWatchingCard(
                      video: activeVideo,
                      course: activeCourse,
                      onPlay: () {
                        if (activeCourse != null) {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StudentCourseDetailScreen(
                                    course: activeCourse!,
                                  ),
                                ),
                              )
                              .then((_) => refreshEnrolled());
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionHeading(
                      title: 'My Courses',
                      count: enrolled.length,
                      action: 'View All',
                      onTap: widget.onViewCourses,
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (enrolled.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCE2EA)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 40,
                              color: Color(0xFF8290A4),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You are not enrolled in any courses yet.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E315F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Explore available courses and enroll to start learning.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: widget.onViewCourses,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D3474),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Browse Courses'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...enrolled.map((course) {
                        final videoCount = course.videos.length;
                        final docCount = course.materials.length;
                        final completedVideos = course.videos
                            .where((v) => v.isCompleted)
                            .length;
                        final calculatedPct = course.videos.isNotEmpty
                            ? ((completedVideos / course.videos.length) * 100)
                                  .round()
                            : 0;
                        final progressPct = course.progressPercentage > 0
                            ? course.progressPercentage
                            : calculatedPct;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C13254A),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => StudentCourseDetailScreen(
                                        course: course,
                                      ),
                                    ),
                                  )
                                  .then((_) => refreshEnrolled());
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail with Badge
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        course.thumbnailUrl,
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: double.infinity,
                                          height: 150,
                                          color: const Color(0xFF1E3470),
                                          child: const Center(
                                            child: Icon(
                                              Icons.school,
                                              size: 48,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2B3A67),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'CS-${course.id}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: Color(0xFF1E315F),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.videocam_outlined,
                                            size: 15,
                                            color: Color(0xFF258DC5),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$videoCount videos',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Icon(
                                              Icons.circle,
                                              size: 4,
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.description_outlined,
                                            size: 15,
                                            color: Color(0xFF258DC5),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$docCount documents',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Text(
                                            '$progressPct%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: Color(0xFF1E315F),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'completed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE6F4EA),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFA8DADC),
                                              ),
                                            ),
                                            child: const Text(
                                              '45 days left',
                                              style: TextStyle(
                                                color: Color(0xFF1E7E34),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progressPct / 100,
                                          minHeight: 6,
                                          color: const Color(0xFF258DC5),
                                          backgroundColor: const Color(
                                            0xFFE2E8F0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ]),
        ),
      ),
    ],
  );
}

class _WelcomeHeader extends StatefulWidget {
  const _WelcomeHeader({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  State<_WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<_WelcomeHeader> {
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _studentData = AuthApi.cachedStudent;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await AuthApi.getProfile();
      if (mounted && response['student'] != null) {
        setState(() {
          _studentData = response['student'] as Map<String, dynamic>;
        });
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  String _getFirstName(String fullName) {
    if (fullName.trim().isEmpty) return 'Priya';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'PS';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _studentData?['fullName'] as String? ?? 'Priya Sharma';
    final firstName = _getFirstName(fullName);
    final initials = _getInitials(fullName);
    final greeting = _getGreeting();

    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Color(0xFFB7C5E3),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3A9AD5),
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({this.video, this.course, required this.onPlay});

  final CourseVideo? video;
  final CourseItem? course;
  final VoidCallback onPlay;

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final videoTitle = video?.title ?? 'Module 4: Binary Trees & Graphs';
    final courseTitle = course?.title ?? 'Data Structures & Algorithms';
    final watchedSecs = video?.watchedSeconds ?? 1115;
    final totalSecs = video?.durationSeconds ?? 2530;
    final progressVal = video != null
        ? (video!.percentageWatched / 100).clamp(0.0, 1.0)
        : 0.44;
    final pctText = (progressVal * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE2EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C13254A),
            blurRadius: 10,
            offset: Offset(0, 4),
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
              TextButton.icon(
                onPressed: onPlay,
                icon: const Text(
                  'Quick Play',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF268DCA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                label: const Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: Color(0xFF268DCA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 105,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F9297),
                      borderRadius: BorderRadius.circular(10),
                      image: video != null && video!.thumbnailUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(video!.thumbnailUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.play_arrow,
                            size: 18,
                            color: Color(0xFF1D3474),
                          ),
                          onPressed: onPlay,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatTime(totalSecs),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF253A65),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      courseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF67748A),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressVal,
                        minHeight: 5,
                        color: const Color(0xFF258DC5),
                        backgroundColor: const Color(0xFFE7EBF1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          size: 11,
                          color: Color(0xFF258DC5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Resume from ${_formatTime(watchedSecs)}',
                          style: const TextStyle(
                            color: Color(0xFF258DC5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$pctText%',
                          style: const TextStyle(
                            color: Color(0xFF67748A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.count,
    required this.action,
    required this.onTap,
  });
  final String title;
  final int count;
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
      const SizedBox(width: 8),
      CircleAvatar(
        radius: 11,
        backgroundColor: const Color(0xFFE5EAF3),
        child: Text(
          '$count',
          style: const TextStyle(
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

class _CoursesContent extends StatefulWidget {
  const _CoursesContent({required this.onEnrolled});

  final VoidCallback onEnrolled;

  @override
  State<_CoursesContent> createState() => _CoursesContentState();
}

class _CoursesContentState extends State<_CoursesContent> {
  late Future<List<CourseItem>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _coursesFuture = CoursesApi.fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
      title: const Text(
        'Explore All Courses',
        style: TextStyle(
          color: Color(0xFF1E315F),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
    ),
    body: FutureBuilder<List<CourseItem>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return const Center(
            child: Text('No courses published yet by admin.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final isEnrolled = course.isEnrolled;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      course.thumbnailUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: const Color(0xFF1E3470),
                        child: const Icon(
                          Icons.school,
                          size: 48,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E315F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course.description.isNotEmpty
                              ? course.description
                              : 'No overview available.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '${course.videos.length} Videos · ${course.materials.length} Materials',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEnrolled
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1D3474),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: isEnrolled
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              StudentCourseDetailScreen(
                                                course: course,
                                              ),
                                        ),
                                      );
                                    }
                                  : () async {
                                      await CoursesApi.enrollCourse(course.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Enrolled in ${course.title}!',
                                            ),
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                          ),
                                        );
                                        widget.onEnrolled();
                                        _refresh();
                                      }
                                    },
                              child: Text(
                                isEnrolled ? 'Enrolled ✓' : 'Enroll Now',
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
          },
        );
      },
    ),
  );
}

class _LiveContent extends StatelessWidget {
  const _LiveContent();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'Live Classes',
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
    currentIndex: selectedIndex,
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
