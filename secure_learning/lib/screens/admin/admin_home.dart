import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/auth_api.dart';
import '../../services/courses_api.dart';
import 'admin_course_detail.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Timer? _heartbeatTimer;
  List<CourseItem> _courses = [];
  bool _loadingCourses = false;

  @override
  void initState() {
    super.initState();
    _sendHeartbeat();
    _fetchAdminCourses();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _sendHeartbeat(),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAdminCourses() async {
    if (mounted) setState(() => _loadingCourses = true);
    final list = await CoursesApi.fetchCourses();
    if (mounted) {
      setState(() {
        _courses = list;
        _loadingCourses = false;
      });
    }
  }

  Future<void> _sendHeartbeat() async {
    try {
      await AuthApi.adminHeartbeat();
    } on AuthApiException {
      // Presence is best effort while the dashboard remains usable offline.
    }
  }

  void _showAddCourseDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final thumbController = TextEditingController();
    PlatformFile? selectedThumbFile;
    bool submitting = false;

    final presetPhotos = [
      'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
      'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600',
      'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600',
      'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
      'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=600',
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add New Course',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Course Name *',
                      hintText: 'e.g., Cyber Security & Network Defense',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Course overview and objectives',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'COURSE THUMBNAIL / PHOTO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Upload Button for Device Photo
                  OutlinedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (res != null && res.files.isNotEmpty) {
                        setDialogState(() {
                          selectedThumbFile = res.files.first;
                          thumbController.text = '';
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.upload_file,
                      color: Color(0xFF101C43),
                    ),
                    label: Text(
                      selectedThumbFile != null
                          ? 'Device Photo: ${selectedThumbFile!.name}'
                          : 'Upload Thumbnail from Device',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101C43),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF101C43),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Selected Photo Preview
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF101C43),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: selectedThumbFile != null
                        ? (selectedThumbFile!.bytes != null
                              ? Image.memory(
                                  selectedThumbFile!.bytes!,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Text(
                                    'Device image selected',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ))
                        : Image.network(
                            thumbController.text.isNotEmpty
                                ? thumbController.text
                                : presetPhotos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Photo Preview',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'Or Pick from Preset Photos:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: presetPhotos.map((url) {
                        final isSelected =
                            selectedThumbFile == null &&
                            (thumbController.text == url ||
                                (thumbController.text.isEmpty &&
                                    url == presetPhotos.first));
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedThumbFile = null;
                              thumbController.text = url;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF101C43)
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(url, fit: BoxFit.cover),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      setDialogState(() => submitting = true);
                      await CoursesApi.createCourse(
                        title: title,
                        description: descController.text.trim(),
                        thumbnailUrl: thumbController.text.trim().isNotEmpty
                            ? thumbController.text.trim()
                            : (selectedThumbFile == null
                                  ? presetPhotos.first
                                  : ''),
                        thumbnailFile: selectedThumbFile,
                      );
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        _fetchAdminCourses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Course added successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF101C43),
                foregroundColor: Colors.white,
              ),
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create Course'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _AdminHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                const _PageIntro(),
                const SizedBox(height: 14),
                _QuickActions(onAddCourse: _showAddCourseDialog),
                const SizedBox(height: 25),
                _SectionTitle(
                  title: 'COURSES MANAGEMENT',
                  action: '${_courses.length} Total',
                ),
                const SizedBox(height: 12),
                if (_loadingCourses)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_courses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No courses available. Click Add Course to create one.',
                      ),
                    ),
                  )
                else
                  ..._courses.map(
                    (course) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            course.thumbnailUrl,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 54,
                              height: 54,
                              color: const Color(0xFF101C43),
                              child: const Icon(
                                Icons.menu_book,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          course.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${course.videos.length} Videos · ${course.materials.length} PDFs',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AdminCourseDetailScreen(course: course),
                                  ),
                                )
                                .then((_) => _fetchAdminCourses());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF101C43),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(60, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _SectionTitle(
                  title: 'KEY METRICS',
                  action: 'Real-time sync',
                ),
                const SizedBox(height: 12),
                const _MetricsGrid(),
                const SizedBox(height: 20),
                const _ExpiringSoonCard(),
                const SizedBox(height: 20),
                const _VideoProcessingCard(),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: const _AdminNavigation(),
  );
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
    decoration: const BoxDecoration(
      color: Color(0xFF101C43),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.wifi_outlined, color: Colors.white, size: 19),
            const SizedBox(width: 13),
            const Icon(Icons.battery_full, color: Colors.white, size: 21),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1B376E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E5594)),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF9AC7FF),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EduTrust Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Institutional Administration',
                    style: TextStyle(color: Color(0xFFB1BCD7), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF193A72),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: Color(0xFF9BC8FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              backgroundColor: Color(0xFF294B8C),
              child: Text(
                'AV',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        const Divider(color: Color(0xFF26365F), height: 1),
        const SizedBox(height: 13),
        const Row(
          children: [
            Icon(Icons.circle, color: Color(0xFF26C693), size: 9),
            SizedBox(width: 8),
            Text(
              'All Nodes Operational',
              style: TextStyle(color: Color(0xFF8CE5C8), fontSize: 12),
            ),
            Spacer(),
            Icon(Icons.security, color: Color(0xFFB4C0DA), size: 14),
            SizedBox(width: 6),
            Text(
              'Knox 3.2',
              style: TextStyle(color: Color(0xFFB4C0DA), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Academic Operations',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF10131B),
        ),
      ),
      SizedBox(height: 3),
      Text(
        'Manage cohorts, deployments & pipelines',
        style: TextStyle(color: Color(0xFF64728B), fontSize: 12),
      ),
    ],
  );
}

class _QuickActions extends StatelessWidget {
  final VoidCallback? onAddCourse;

  const _QuickActions({this.onAddCourse});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ActionButton(
        icon: Icons.add,
        label: 'Add Course',
        filled: true,
        onTap: onAddCourse,
      ),
      const SizedBox(width: 8),
      _ActionButton(
        icon: Icons.person_add_alt_1_outlined,
        label: 'Add Student',
      ),
      const SizedBox(width: 8),
      _ActionButton(icon: Icons.cloud_upload_outlined, label: 'Upload Video'),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.filled = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onTap ?? () {},
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: filled ? Colors.white : const Color(0xFF233453),
          backgroundColor: filled ? const Color(0xFF101C43) : Colors.white,
          side: BorderSide(
            color: filled ? const Color(0xFF101C43) : const Color(0xFFDCE3EC),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF60728F),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: .5,
        ),
      ),
      const Spacer(),
      Text(
        action,
        style: const TextStyle(color: Color(0xFF246CF0), fontSize: 12),
      ),
    ],
  );
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Row(
        children: [
          _MetricCard(
            label: 'TOTAL STUDENTS',
            value: '14,820',
            icon: Icons.school_outlined,
            color: Color(0xFFEAF2FF),
          ),
          SizedBox(width: 10),
          _MetricCard(
            label: 'ACTIVE STUDENTS',
            value: '12,450',
            icon: Icons.verified_user_outlined,
            color: Color(0xFFE8FBF3),
          ),
        ],
      ),
      SizedBox(height: 10),
      Row(
        children: [
          _MetricCard(
            label: 'TOTAL COURSES',
            value: '384',
            icon: Icons.menu_book_outlined,
            color: Color(0xFFF7ECFF),
          ),
          SizedBox(width: 10),
          _MetricCard(
            label: 'TOTAL VIDEOS',
            value: '2,190',
            icon: Icons.videocam_outlined,
            color: Color(0xFFE7FAFF),
          ),
        ],
      ),
      SizedBox(height: 10),
      Row(
        children: [
          _MetricCard(
            label: 'EXPIRED STUDENTS',
            value: '320',
            icon: Icons.timer_outlined,
            color: Color(0xFFFFEEEE),
          ),
          SizedBox(width: 10),
          _MetricCard(
            label: 'EXPIRING 7 DAYS',
            value: '85',
            icon: Icons.error_outline,
            color: Color(0xFFFFF8E8),
            valueColor: Color(0xFFD16B00),
          ),
        ],
      ),
      SizedBox(height: 10),
      Row(
        children: [
          _MetricCard(
            label: 'PUBLISHED',
            value: '342',
            icon: Icons.check,
            color: Color(0xFFE8FBF3),
          ),
          SizedBox(width: 10),
          _MetricCard(
            label: 'ENCODING QUEUE',
            value: '18',
            icon: Icons.sync,
            color: Color(0xFFFFF2E8),
            valueColor: Color(0xFFE44616),
          ),
        ],
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.valueColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 106,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E6EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B1D35),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64728B),
                    fontSize: 10,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 17, color: const Color(0xFF2370DB)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF101522),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExpiringSoonCard extends StatelessWidget {
  const _ExpiringSoonCard();

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Color(0xFFFF8C00),
              size: 19,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiring Soon',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Active Cohort Alerts',
                    style: TextStyle(color: Color(0xFF8794A8), fontSize: 10),
                  ),
                ],
              ),
            ),
            Text(
              'View (85)  ›',
              style: TextStyle(
                color: Color(0xFF071453),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0xFFE9EEF4)),
        ...const [
          _ExpiringStudent(
            initials: 'ER',
            name: 'Elena Rostova',
            course: 'CS-409 · Adv. Cryptography',
            days: 'In 2 days',
          ),
          _ExpiringStudent(
            initials: 'MC',
            name: 'Marcus Chen',
            course: 'SYS-502 · Dist. Architectures',
            days: 'In 4 days',
          ),
          _ExpiringStudent(
            initials: 'NA',
            name: 'Nia Adebayo',
            course: 'MATH-311 · Formal Verification',
            days: 'In 5 days',
          ),
        ],
      ],
    ),
  );
}

class _ExpiringStudent extends StatelessWidget {
  const _ExpiringStudent({
    required this.initials,
    required this.name,
    required this.course,
    required this.days,
  });
  final String initials;
  final String name;
  final String course;
  final String days;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE7EDF5),
          child: Text(
            initials,
            style: const TextStyle(color: Color(0xFF233453), fontSize: 12),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                course,
                style: const TextStyle(color: Color(0xFF64728B), fontSize: 10),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFD36A)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  days,
                  style: const TextStyle(color: Color(0xFFCC7000), fontSize: 9),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF142343),
            side: const BorderSide(color: Color(0xFFDCE3EC)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Extend',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _VideoProcessingCard extends StatelessWidget {
  const _VideoProcessingCard();

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.sync, color: Color(0xFF10245A)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Videos Processing',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Aegis Media Cluster - 4 Cores',
                    style: TextStyle(color: Color(0xFF8794A8), fontSize: 10),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFE7FAF1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF009A63),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 25, color: Color(0xFFE9EEF4)),
        const _ProgressRow(
          title: 'Lecture 08: Distributed Ledger Co...',
          subtitle: 'CS-409 Cryptographic Protocols',
          progress: .78,
        ),
        const _ProgressRow(
          title: 'Module 4: Neural Architecture Sea...',
          subtitle: 'AI-610 Deep Learning Foundations',
          progress: .45,
        ),
        const _ProgressRow(
          title: 'Seminar: Quantum Cryptography F...',
          subtitle: 'PHYS-420 Applied Quantum Systems',
          progress: .92,
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Text(
              'Encoding via Pipeline v4.2',
              style: TextStyle(color: Color(0xFF8794A8), fontSize: 10),
            ),
            Spacer(),
            Icon(Icons.sync, size: 13, color: Color(0xFF10245A)),
            SizedBox(width: 4),
            Text(
              'Refresh',
              style: TextStyle(
                color: Color(0xFF10245A),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.subtitle,
    required this.progress,
  });
  final String title;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64728B), fontSize: 10),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFE9EEF4),
            color: const Color(0xFF10152D),
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E6EE)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080B1D35),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation();

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: 0,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFF101C43),
    unselectedItemColor: const Color(0xFF92A3C1),
    selectedFontSize: 10,
    unselectedFontSize: 10,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        label: 'Courses',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.school_outlined),
        label: 'Students',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ],
  );
}
