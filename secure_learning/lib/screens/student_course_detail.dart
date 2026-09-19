import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import '../services/courses_api.dart';

class StudentCourseDetailScreen extends StatefulWidget {
  final CourseItem course;

  const StudentCourseDetailScreen({super.key, required this.course});

  @override
  State<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState extends State<StudentCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late CourseItem _course;
  bool _loading = false;
  late TabController _tabController;
  CourseVideo? _selectedVideo;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _tabController = TabController(length: 2, vsync: this);
    _refreshCourseDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCourseDetails() async {
    setState(() => _loading = true);
    final updated = await CoursesApi.fetchCourseDetails(_course.id);
    if (mounted && updated != null) {
      setState(() {
        _course = updated;
        if (_course.videos.isNotEmpty && _selectedVideo == null) {
          _selectedVideo = _course.videos.firstWhere(
            (v) => !v.isCompleted && v.watchedSeconds > 0,
            orElse: () => _course.videos.first,
          );
        }
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _openVideoPlayer(CourseVideo video) {
    setState(() => _selectedVideo = video);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentVideoPlayerScreen(
          video: video,
          course: _course,
          onProgressUpdate: (watchedSecs, totalSecs) async {
            await CoursesApi.updateVideoProgress(
              videoId: video.id,
              watchedSeconds: watchedSecs,
              totalSeconds: totalSecs,
            );
          },
        ),
      ),
    ).then((_) => _refreshCourseDetails());
  }

  void _openPdfViewer(CourseMaterial material) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            StudentMaterialViewerScreen(material: material, course: _course),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final videos = _course.videos;
    final materials = _course.materials;
    final completedCount = videos.where((v) => v.isCompleted).length;
    final totalWatchedSecs = videos.fold<int>(
      0,
      (sum, v) => sum + v.watchedSeconds,
    );
    final totalDurationSecs = videos.fold<int>(
      0,
      (sum, v) => sum + v.durationSeconds,
    );
    final progressPct = _course.progressPercentage > 0
        ? _course.progressPercentage
        : (totalDurationSecs > 0
              ? ((totalWatchedSecs / totalDurationSecs) * 100).round().clamp(
                  0,
                  100,
                )
              : (videos.isNotEmpty
                    ? ((completedCount / videos.length) * 100).round()
                    : 0));

    final activeVideo =
        _selectedVideo ?? (videos.isNotEmpty ? videos.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _course.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF1D3474),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Banner (Image 1)
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF1D3474),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Image.network(
                                    _course.thumbnailUrl,
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 160,
                                      color: const Color(0xFF0F172A),
                                      child: const Icon(
                                        Icons.school,
                                        size: 64,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          const Color(
                                            0xFF1D3474,
                                          ).withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2B3A67),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'CS-${_course.id} • CORE CURRICULUM',
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
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _course.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.play_circle_fill_outlined,
                                          color: Color(0xFF38BDF8),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${videos.length} videos',
                                          style: const TextStyle(
                                            color: Color(0xFF93C5FD),
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
                                            color: Colors.white38,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.description_outlined,
                                          color: Color(0xFF38BDF8),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${materials.length} documents',
                                          style: const TextStyle(
                                            color: Color(0xFF93C5FD),
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
                                            color: Colors.white38,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.verified,
                                          color: Color(0xFF10B981),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Accredited',
                                          style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 12,
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
                        ),

                        // Overall Progress Card (Image 1)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Overall Progress',
                                    style: TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF93C5FD),
                                      ),
                                    ),
                                    child: Text(
                                      '$progressPct% completed',
                                      style: const TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedCount of ${videos.length} curriculum modules completed',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (progressPct / 100).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  color: const Color(0xFF258DC5),
                                  backgroundColor: const Color(0xFFE2E8F0),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '45 days validity left',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.circle,
                                      size: 3,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  Text(
                                    'Certificate on completion',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Tab Bar (Videos / Materials)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFF1D3474),
                            unselectedLabelColor: const Color(0xFF64748B),
                            indicatorColor: const Color(0xFF1D3474),
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            tabs: [
                              Tab(text: 'Videos  ${videos.length}'),
                              Tab(text: 'Materials  ${materials.length}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tab Contents
                        SizedBox(
                          height: 480,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Videos List (Matching Image 1)
                              videos.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No videos uploaded for this course yet.',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: videos.length,
                                      itemBuilder: (context, idx) {
                                        final video = videos[idx];
                                        final isSelected =
                                            activeVideo?.id == video.id;
                                        final isDone = video.isCompleted;
                                        final isStarted =
                                            video.watchedSeconds > 0;
                                        final pct = video.percentageWatched;

                                        return Card(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: isSelected
                                                  ? const Color(0xFF258DC5)
                                                  : const Color(0xFFE2E8F0),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          elevation: isSelected ? 2 : 0,
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(12),
                                            onTap: () =>
                                                _openVideoPlayer(video),
                                            leading: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isDone
                                                    ? const Color(0xFF1D4ED8)
                                                    : isSelected
                                                    ? const Color(0xFFDBEAFE)
                                                    : const Color(0xFFF1F5F9),
                                              ),
                                              alignment: Alignment.center,
                                              child: isDone
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 20,
                                                      color: Colors.white,
                                                    )
                                                  : Text(
                                                      (idx + 1)
                                                          .toString()
                                                          .padLeft(2, '0'),
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? const Color(
                                                                0xFF1D4ED8,
                                                              )
                                                            : const Color(
                                                                0xFF475569,
                                                              ),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                            ),
                                            title: Text(
                                              video.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    video.description,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.access_time,
                                                        size: 13,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatDuration(
                                                          video.durationSeconds,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                            0xFF64748B,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      if (isStarted &&
                                                          !isDone) ...[
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                              ),
                                                          child: Icon(
                                                            Icons.circle,
                                                            size: 3,
                                                            color: Color(
                                                              0xFF94A3B8,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '$pct% watched',
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF1D4ED8,
                                                                ),
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            trailing: isDone
                                                ? Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEFF6FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Completed',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF1D4ED8,
                                                        ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEFF6FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.play_arrow,
                                                          size: 14,
                                                          color: Color(
                                                            0xFF1D4ED8,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        Text(
                                                          _formatDuration(
                                                            video.watchedSeconds >
                                                                    0
                                                                ? video
                                                                      .watchedSeconds
                                                                : 760,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF1D4ED8,
                                                                ),
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        );
                                      },
                                    ),

                              // Materials List Tab
                              materials.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No study materials added yet.',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: materials.length,
                                      itemBuilder: (context, idx) {
                                        final mat = materials[idx];
                                        return Card(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: ListTile(
                                            onTap: () => _openPdfViewer(mat),
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF2F2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.picture_as_pdf,
                                                color: Color(0xFFDC2626),
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
                                              'PDF Document • ${mat.fileSizeKb} KB',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                                color: Color(0xFF1D3474),
                                              ),
                                              onPressed: () =>
                                                  _openPdfViewer(mat),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Resume Action Bar (Matching Image 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (activeVideo != null) {
                          _openVideoPlayer(activeVideo);
                        }
                      },
                      icon: const Icon(Icons.play_circle_fill, size: 20),
                      label: Text(
                        activeVideo != null
                            ? 'Resume Next: ${activeVideo.title} (${_formatDuration(activeVideo.watchedSeconds > 0 ? activeVideo.watchedSeconds : 760)})'
                            : 'Start Learning',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Full Video Player Screen with Bunny CDN Controls, Speed, Quality & Fullscreen (Matching Image 3)
class StudentVideoPlayerScreen extends StatefulWidget {
  final CourseVideo video;
  final CourseItem course;
  final Function(int watchedSeconds, int totalSeconds) onProgressUpdate;

  const StudentVideoPlayerScreen({
    super.key,
    required this.video,
    required this.course,
    required this.onProgressUpdate,
  });

  @override
  State<StudentVideoPlayerScreen> createState() =>
      _StudentVideoPlayerScreenState();
}

class _StudentVideoPlayerScreenState extends State<StudentVideoPlayerScreen> {
  bool _isPlaying = true;
  bool _isFullscreen = false;
  double _playbackSpeed = 1.0;
  String _quality = '720p';
  late int _watchedSecs;
  late int _totalSecs;
  Timer? _timer;

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  final List<String> _qualityOptions = ['360p', '480p', '720p', '1080p'];

  VideoPlayerController? _videoPlayerController;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _watchedSecs = widget.video.watchedSeconds;
    _totalSecs = widget.video.durationSeconds;
    _initWebPlayer();
  }

  void _initWebPlayer() {
    String videoId = widget.video.bunnyVideoId;
    if (videoId.isEmpty && widget.video.playUrl.isNotEmpty) {
      final Uri? uri = Uri.tryParse(widget.video.playUrl);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        videoId = uri.pathSegments.first;
      }
    }

    final cleanVideoId = videoId;
    final libraryId = widget.video.bunnyLibraryId;

    final embedUrl = widget.video.iframeUrl.isNotEmpty
        ? widget.video.iframeUrl
        : 'https://iframe.mediadelivery.net/embed/$libraryId/$cleanVideoId?autoplay=true&loop=false&muted=false&preload=true';

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF000000))
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        )
        ..addJavaScriptChannel(
          'VideoProgress',
          onMessageReceived: (message) => _onBunnyPlayerMessage(message.message),
        )
        ..loadHtmlString(_bunnyPlayerHtml(embedUrl, _watchedSecs));
      setState(() => _webViewController = controller);
    } catch (e) {
      debugPrint('WebViewController init error: $e');
    }
  }

  int _lastReportedPosition = -1;

  String _bunnyPlayerHtml(String embedUrl, int resumeAtSeconds) {
    final encodedUrl = jsonEncode(embedUrl);
    final safeResumeAt = resumeAtSeconds < 0 ? 0 : resumeAtSeconds;
    return '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"><style>html,body,iframe{margin:0;width:100%;height:100%;border:0;background:#000;overflow:hidden}</style></head>
<body><iframe id="bunny-stream-player" src=$encodedUrl allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe>
<script src="https://assets.mediadelivery.net/playerjs/player-0.1.0.min.js"></script>
<script>
  function report(event, value) { VideoProgress.postMessage(JSON.stringify({event:event, value:value || {}})); }
  window.addEventListener('load', function () {
    var player = new playerjs.Player(document.getElementById('bunny-stream-player'));
    function timing(raw) {
      try { var value = typeof raw === 'string' ? JSON.parse(raw) : raw; report('timeupdate', value); } catch (_) {}
    }
    player.on('ready', function () { player.getDuration(function (duration) { var resumeAt = Math.min($safeResumeAt, duration || 0); if (resumeAt > 0) player.setCurrentTime(resumeAt); report('duration', {seconds: resumeAt, duration: duration}); }); });
    player.on('timeupdate', timing);
    player.on('pause', function () { player.getCurrentTime(function (seconds) { player.getDuration(function (duration) { report('pause', {seconds:seconds, duration:duration}); }); }); });
    player.on('ended', function () { player.getDuration(function (duration) { report('ended', {seconds:duration, duration:duration}); }); });
  });
</script></body></html>''';
  }

  void _onBunnyPlayerMessage(String rawMessage) {
    try {
      if (!mounted) return;
      final message = jsonDecode(rawMessage) as Map<String, dynamic>;
      final event = message['event'] as String? ?? '';
      final value = message['value'] as Map<String, dynamic>? ?? const {};
      final seconds = (value['seconds'] as num?)?.floor() ?? 0;
      final duration = (value['duration'] as num?)?.floor() ?? 0;
      if (duration <= 0) return;
      final watched = seconds.clamp(0, duration).toInt();
      setState(() {
        _watchedSecs = watched;
        _totalSecs = duration;
        _isPlaying = event != 'pause' && event != 'ended';
      });
      final shouldSave = event == 'pause' || event == 'ended' ||
          _lastReportedPosition < 0 || watched - _lastReportedPosition >= 5;
      if (shouldSave) {
        _lastReportedPosition = watched;
        widget.onProgressUpdate(watched, duration);
      }
    } catch (e) {
      debugPrint('Invalid Bunny player progress payload: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _watchedSecs < _totalSecs) {
          setState(() {
            _watchedSecs += 1;
          });
          widget.onProgressUpdate(_watchedSecs, _totalSecs);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized) {
        if (_isPlaying) {
          _videoPlayerController!.play();
        } else {
          _videoPlayerController!.pause();
        }
      }
      if (_isPlaying) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showSpeedPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Playback Speed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ..._speedOptions.map(
            (speed) => ListTile(
              title: Text(
                '${speed}x',
                style: TextStyle(
                  color: _playbackSpeed == speed
                      ? const Color(0xFF38BDF8)
                      : Colors.white70,
                  fontWeight: _playbackSpeed == speed
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: _playbackSpeed == speed
                  ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                  : null,
              onTap: () {
                setState(() => _playbackSpeed = speed);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Video Quality',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ..._qualityOptions.map(
            (q) => ListTile(
              title: Text(
                q,
                style: TextStyle(
                  color: _quality == q
                      ? const Color(0xFF38BDF8)
                      : Colors.white70,
                  fontWeight: _quality == q
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: _quality == q
                  ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                  : null,
              onTap: () {
                setState(() => _quality = q);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressVal = _totalSecs > 0
        ? (_watchedSecs / _totalSecs).clamp(0.0, 1.0)
        : 0.0;
    final pctWatched = (progressVal * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bunny Video Player Container (Image 3)
            Container(
              height: _isFullscreen
                  ? MediaQuery.of(context).size.height * 0.9
                  : 230,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized)
                    AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    )
                  else if (_webViewController != null)
                    WebViewWidget(controller: _webViewController!)
                  else
                    Image.network(
                      widget.video.thumbnailUrl.isNotEmpty
                          ? widget.video.thumbnailUrl
                          : widget.course.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF0F172A),
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 72,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  if (!_isPlaying &&
                      _videoPlayerController == null &&
                      _webViewController == null)
                    Container(color: const Color(0x73000000)),

                  // Header Controls Overlay
                  if (false)
                    Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE DRM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            if (!_isFullscreen)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Details Container (Image 3)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'CS-${widget.course.id} • Module 04',
                                    style: const TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Device Verified',
                                    style: TextStyle(
                                      color: Color(0xFF15803D),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.video.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Course: ${widget.course.title}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '${_totalSecs < 60 ? '$_totalSecs sec' : '${(_totalSecs / 60).toStringAsFixed(1)} mins'} total',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.circle,
                                    size: 4,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                Text(
                                  '$pctWatched% watched',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.circle,
                                    size: 4,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                const Text(
                                  'Lab guide attached',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.note_outlined, size: 16),
                                label: const Text('Notes'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LESSON DESCRIPTION Card (Image 3)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.subject,
                                  size: 18,
                                  color: Color(0xFF1D4ED8),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'VIDEO DESCRIPTION',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  'Module Syllabus',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.video.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                height: 1.5,
                              ),
                            ),
                            if (false) const SizedBox(height: 14),
                            if (false)
                              Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Covered in this session:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '• Reconnaissance & Port Mapping with Nmap\n• CVSS v3.1 scoring formulas and enterprise risk matrices\n• Privilege escalation vector isolation in cloud VMs',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // UP NEXT IN CURRICULUM Card (Image 3)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'UP NEXT IN CURRICULUM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  'Auto-play is ON',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'NEXT LESSON • MODULE 05',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '05. Intrusion Detection Systems (IDS)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Snort, Suricata & Signature Design',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
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
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Protected institutional device session • EduTrust Knox 3.2',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Study Material Viewer Screen (Matching Image 4)
class StudentMaterialViewerScreen extends StatelessWidget {
  final CourseMaterial material;
  final CourseItem course;

  const StudentMaterialViewerScreen({
    super.key,
    required this.material,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Protected View • CS-401',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Header (Image 4)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3470),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EDUTRUST ACADEMIC PRESS',
                        style: TextStyle(
                          color: Color(0xFF1E3470),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'DOC-CS401-REV4',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),

                  Text(
                    'SECTION 3.2 • VULNERABILITY SCANNING & ANALYSIS',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Network Threat Vector Mapping & CVSS Scoring',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.6,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'In perimeter network security frameworks compliant with ',
                        ),
                        TextSpan(
                          text: 'NIST SP 800-115',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              ', automated vulnerability assessments must precede remediation staging. Automated port interrogation tools, when executed across subnet topologies, generate baseline vulnerability telemetries mapped against the Common Vulnerability Scoring System (',
                        ),
                        TextSpan(
                          text: 'CVSS v3.1',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ').'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Threat Telemetry Figure Box (Image 4)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.hub_outlined,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Figure 3.1: Threat Ingress & Telemetry Correlation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  children: const [
                                    Text(
                                      'ATTACK VECTOR',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Network (AV:N)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  children: const [
                                    Text(
                                      'COMPLEXITY',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Low (AC:L)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
                                ),
                                child: Column(
                                  children: const [
                                    Text(
                                      'BASE SCORE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFDC2626),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '8.8 HIGH',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nmap Code Block (Image 4)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '# Perimeter scan execution with host discovery',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'nmap -sV -sC -O -T4 192.168.1.0/24 -oX audit.xml',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '> 3 filtered ports detected; IDS alert triggered',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'When evaluating intrusion signatures, examiners must isolate false positives generated by stateful packet filtering. Signature patterns identified by rule groups in Suricata and Snort should be cross-verified against system audit logs before modifying perimeter rulesets.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Bottom Page Pill Bar (Image 4: "< Page 3 of 24 >")
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Page 3 of 24',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
