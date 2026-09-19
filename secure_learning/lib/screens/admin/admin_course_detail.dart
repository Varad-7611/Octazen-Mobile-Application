import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/courses_api.dart';

class AdminCourseDetailScreen extends StatefulWidget {
  final CourseItem course;

  const AdminCourseDetailScreen({super.key, required this.course});

  @override
  State<AdminCourseDetailScreen> createState() =>
      _AdminCourseDetailScreenState();
}

class _AdminCourseDetailScreenState extends State<AdminCourseDetailScreen> {
  late CourseItem _course;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _refreshCourse();
  }

  Future<void> _refreshCourse() async {
    setState(() => _loading = true);
    final updated = await CoursesApi.fetchCourseDetails(_course.id);
    if (mounted && updated != null) {
      setState(() {
        _course = updated;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showAddContentDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddContentBottomSheet(
        courseId: _course.id,
        onContentAdded: () {
          Navigator.of(ctx).pop();
          _refreshCourse();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Content added successfully to course!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteVideo(CourseVideo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete video?'),
        content: Text(
          '“${video.title}” will be removed from this course and from every student’s progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final deleted = await CoursesApi.deleteVideoFromCourse(
      courseId: _course.id,
      videoId: video.id,
    );
    if (!mounted) return;
    if (deleted) {
      await _refreshCourse();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video removed from the course.')),
      );
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete the video. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _course.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF101C43),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCourse,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Header Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          _course.thumbnailUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: const Color(0xFF1E3470),
                            child: const Center(
                              child: Icon(
                                Icons.menu_book,
                                size: 48,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Published',
                                      style: TextStyle(
                                        color: Color(0xFF166534),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_course.videos.length} Videos · ${_course.materials.length} PDFs',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _course.title,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _course.description.isNotEmpty
                                    ? _course.description
                                    : 'No description provided.',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Add Content Button Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'COURSE CONTENT',
                        style: TextStyle(
                          color: Color(0xFF64728B),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddContentDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Add Content',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF101C43),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Videos Section
                  const Text(
                    'Videos',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_course.videos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 36,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No videos added yet for this course.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._course.videos.map(
                      (video) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.play_circle_fill,
                              color: Color(0xFF2563EB),
                              size: 26,
                            ),
                          ),
                          title: Text(
                            video.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: video.description.trim().isEmpty
                              ? null
                              : Text(
                                  video.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete video',
                            onPressed: () => _deleteVideo(video),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // PDF Notes Section
                  const Text(
                    'Study Materials (PDF Notes)',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_course.materials.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 36,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No PDF study materials added yet for this course.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._course.materials.map(
                      (mat) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Color(0xFFEF4444),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            mat.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'PDF Document · ${mat.fileSizeKb} KB',
                            style: const TextStyle(fontSize: 12),
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

class _AddContentBottomSheet extends StatefulWidget {
  final dynamic courseId;
  final VoidCallback onContentAdded;

  const _AddContentBottomSheet({
    required this.courseId,
    required this.onContentAdded,
  });

  @override
  State<_AddContentBottomSheet> createState() => _AddContentBottomSheetState();
}

class _AddContentBottomSheetState extends State<_AddContentBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Video Form
  final _videoTitleController = TextEditingController();
  final _videoDescController = TextEditingController();
  final _videoThumbController = TextEditingController();
  final _videoUrlController = TextEditingController();
  PlatformFile? _videoFile;
  PlatformFile? _videoThumbFile;
  bool _submittingVideo = false;

  // Material Form
  final _materialTitleController = TextEditingController();
  final _materialPathController = TextEditingController();
  PlatformFile? _materialFile;
  bool _submittingMaterial = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoTitleController.dispose();
    _videoDescController.dispose();
    _videoThumbController.dispose();
    _videoUrlController.dispose();
    _materialTitleController.dispose();
    _materialPathController.dispose();
    super.dispose();
  }

  Future<void> _submitVideo() async {
    final title = _videoTitleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _submittingVideo = true);
    await CoursesApi.addVideoToCourse(
      courseId: widget.courseId,
      title: title,
      description: _videoDescController.text.trim(),
      thumbnailUrl: _videoThumbController.text.trim(),
      videoUrl: _videoUrlController.text.trim(),
      videoFile: _videoFile,
      thumbnailFile: _videoThumbFile,
    );
    setState(() => _submittingVideo = false);
    widget.onContentAdded();
  }

  Future<void> _submitMaterial() async {
    final title = _materialTitleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _submittingMaterial = true);
    await CoursesApi.addMaterialToCourse(
      courseId: widget.courseId,
      title: title,
      filePath: _materialPathController.text.trim().isNotEmpty
          ? _materialPathController.text.trim()
          : 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      materialFile: _materialFile,
    );
    setState(() => _submittingMaterial = false);
    widget.onContentAdded();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add Content to Course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF101C43),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF101C43),
            tabs: const [
              Tab(icon: Icon(Icons.videocam), text: 'Add Video'),
              Tab(icon: Icon(Icons.picture_as_pdf), text: 'Add PDF Notes'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Add Video Tab
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _videoTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Video Title *',
                          hintText: 'e.g., Lecture 1: Core Concepts',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _videoDescController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief summary of the video content',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pick Video File Button
                      const Text(
                        'VIDEO FILE FROM DEVICE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.video,
                            withData: true,
                          );
                          if (res != null && res.files.isNotEmpty) {
                            setState(() {
                              _videoFile = res.files.first;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.video_file,
                          color: Color(0xFF101C43),
                        ),
                        label: Text(
                          _videoFile != null
                              ? 'Selected: ${_videoFile!.name} (${(_videoFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB)'
                              : 'Upload Video File from Device',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101C43),
                            fontSize: 13,
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

                      const SizedBox(height: 14),

                      // Pick Thumbnail Photo Button
                      const Text(
                        'VIDEO THUMBNAIL PHOTO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (res != null && res.files.isNotEmpty) {
                            setState(() {
                              _videoThumbFile = res.files.first;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.add_a_photo,
                          color: Color(0xFF101C43),
                        ),
                        label: Text(
                          _videoThumbFile != null
                              ? 'Selected Photo: ${_videoThumbFile!.name}'
                              : 'Upload Thumbnail from Device',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101C43),
                            fontSize: 13,
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

                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _submittingVideo ? null : _submitVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF101C43),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _submittingVideo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Video Content'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add PDF Notes Tab
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _materialTitleController,
                        decoration: const InputDecoration(
                          labelText: 'PDF Document Title *',
                          hintText: 'e.g., Module 1 Practice Questions PDF',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'PDF FILE FROM DEVICE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            withData: true,
                          );
                          if (res != null && res.files.isNotEmpty) {
                            setState(() {
                              _materialFile = res.files.first;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Color(0xFFEF4444),
                        ),
                        label: Text(
                          _materialFile != null
                              ? 'Selected: ${_materialFile!.name} (${(_materialFile!.size / 1024).toStringAsFixed(0)} KB)'
                              : 'Upload PDF Notes from Device',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101C43),
                            fontSize: 13,
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

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _submittingMaterial
                              ? null
                              : _submitMaterial,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF101C43),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _submittingMaterial
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save PDF Study Notes'),
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
    );
  }
}
