import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_api.dart';

class CourseItem {
  final dynamic id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final bool isPublished;
  final bool isEnrolled;
  final int completedVideos;
  final int totalVideos;
  final int progressPercentage;
  final int daysLeft;
  final String createdAt;
  final List<CourseVideo> videos;
  final List<CourseMaterial> materials;

  CourseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.isPublished,
    this.isEnrolled = false,
    this.completedVideos = 0,
    this.totalVideos = 0,
    this.progressPercentage = 0,
    this.daysLeft = 45,
    required this.createdAt,
    this.videos = const [],
    this.materials = const [],
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    var rawVideos = json['videos'] as List? ?? [];
    var rawMaterials = json['materials'] as List? ?? [];

    return CourseItem(
      id: json['id'],
      title: json['title'] as String? ?? 'Untitled Course',
      description: json['description'] as String? ?? '',
      thumbnailUrl:
          json['thumbnail_url'] as String? ??
          json['thumbnailUrl'] as String? ??
          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
      isPublished: json['is_published'] as bool? ?? true,
      isEnrolled: json['isEnrolled'] as bool? ?? false,
      completedVideos: json['completedVideos'] as int? ?? 0,
      totalVideos: json['totalVideos'] as int? ?? rawVideos.length,
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      daysLeft: json['daysLeft'] as int? ?? 45,
      createdAt: json['created_at'] as String? ?? '',
      videos: rawVideos
          .map((v) => CourseVideo.fromJson(v as Map<String, dynamic>))
          .toList(),
      materials: rawMaterials
          .map((m) => CourseMaterial.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CourseVideo {
  final dynamic id;
  final dynamic courseId;
  final String title;
  final String description;
  final String bunnyVideoId;
  final String bunnyLibraryId;
  final String playUrl;
  final String iframeUrl;
  final String hlsUrl;
  final String thumbnailUrl;
  final int durationSeconds;
  final int watchedSeconds;
  final int percentageWatched;
  final bool isCompleted;

  CourseVideo({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.bunnyVideoId,
    this.bunnyLibraryId = '',
    required this.playUrl,
    required this.iframeUrl,
    required this.hlsUrl,
    required this.thumbnailUrl,
    this.durationSeconds = 30,
    this.watchedSeconds = 0,
    this.percentageWatched = 0,
    this.isCompleted = false,
  });

  factory CourseVideo.fromJson(Map<String, dynamic> json) => CourseVideo(
    id: json['id'],
    courseId: json['course_id'],
    title: json['title'] as String? ?? 'Untitled Video',
    description: json['description'] as String? ?? '',
    bunnyVideoId:
        json['bunny_video_id'] as String? ??
        json['bunnyVideoId'] as String? ??
        '',
    bunnyLibraryId:
        json['bunny_library_id'] as String? ??
        json['bunnyLibraryId'] as String? ??
        '',
    playUrl: json['playUrl'] as String? ?? '',
    iframeUrl: json['iframeUrl'] as String? ?? '',
    hlsUrl: json['hlsUrl'] as String? ?? '',
    thumbnailUrl: json['thumbnail_url'] as String? ?? '',
    durationSeconds:
        json['duration_seconds'] as int? ??
        json['durationSeconds'] as int? ??
        0,
    watchedSeconds: json['watchedSeconds'] as int? ?? 0,
    percentageWatched: json['percentageWatched'] as int? ?? 0,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  CourseVideo copyWith({
    int? watchedSeconds,
    int? percentageWatched,
    bool? isCompleted,
  }) {
    return CourseVideo(
      id: id,
      courseId: courseId,
      title: title,
      description: description,
      bunnyVideoId: bunnyVideoId,
      bunnyLibraryId: bunnyLibraryId,
      playUrl: playUrl,
      iframeUrl: iframeUrl,
      hlsUrl: hlsUrl,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      percentageWatched: percentageWatched ?? this.percentageWatched,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class CourseMaterial {
  final dynamic id;
  final dynamic courseId;
  final String title;
  final String filePath;
  final String fileType;
  final int fileSizeKb;

  CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.fileSizeKb,
  });

  factory CourseMaterial.fromJson(Map<String, dynamic> json) => CourseMaterial(
    id: json['id'],
    courseId: json['course_id'],
    title: json['title'] as String? ?? 'PDF Document',
    filePath: json['file_path'] as String? ?? json['filePath'] as String? ?? '',
    fileType: json['file_type'] as String? ?? 'pdf',
    fileSizeKb: json['file_size_kb'] as int? ?? 512,
  );
}

class CoursesApi {
  static String get baseUrl => ApiConfig.coursesUrl;
  static Map<String, String> _getHeaders() {
    final token = AuthApi.studentAccessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static final Set<String> enrolledIds = {'1'};

  static Future<http.MultipartFile> _createMultipartFile(
    String fieldName,
    PlatformFile file,
  ) async {
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        fieldName,
        file.bytes!,
        filename: file.name,
      );
    } else if (file.path != null) {
      return await http.MultipartFile.fromPath(
        fieldName,
        file.path!,
        filename: file.name,
      );
    }
    throw Exception('File data unavailable');
  }

  static Future<List<CourseItem>> fetchCourses() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['courses'] as List? ?? [];
        return list.map((item) {
          final course = CourseItem.fromJson(item as Map<String, dynamic>);
          final isEnrolled = course.isEnrolled;
          if (isEnrolled) {
            enrolledIds.add(course.id.toString());
          }
          return course;
        }).toList();
      }
    } catch (e) {
      print('[CoursesApi] Error fetching courses: $e');
    }
    return _fallbackCourses().map((c) {
      final isEnrolled = c.isEnrolled || enrolledIds.contains(c.id.toString());
      return CourseItem(
        id: c.id,
        title: c.title,
        description: c.description,
        thumbnailUrl: c.thumbnailUrl,
        isPublished: c.isPublished,
        isEnrolled: isEnrolled,
        completedVideos: c.completedVideos,
        totalVideos: c.totalVideos,
        progressPercentage: c.progressPercentage,
        daysLeft: c.daysLeft,
        createdAt: c.createdAt,
        videos: c.videos,
        materials: c.materials,
      );
    }).toList();
  }

  static Future<List<CourseItem>> fetchEnrolledCourses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/enrolled'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['courses'] as List? ?? [];
        return list
            .map((item) => CourseItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[CoursesApi] Error fetching enrolled courses: $e');
    }
    final all = await fetchCourses();
    return all.where((c) => c.isEnrolled).toList();
  }

  static Future<bool> enrollCourse(dynamic courseId) async {
    enrolledIds.add(courseId.toString());
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$courseId/enroll'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('[CoursesApi] Error enrolling course: $e');
    }
    return true;
  }

  static Future<void> updateVideoProgress({
    required dynamic videoId,
    required int watchedSeconds,
    required int totalSeconds,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/video-progress'),
        headers: _getHeaders(),
        body: jsonEncode({
          'videoId': videoId,
          'watchedSeconds': watchedSeconds,
        }),
      );
    } catch (e) {
      print('[CoursesApi] Error updating video progress: $e');
    }
  }

  static Future<CourseItem?> fetchCourseDetails(dynamic courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$courseId'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['course'] != null) {
          return CourseItem.fromJson(data['course'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('[CoursesApi] Error fetching course details: $e');
    }
    return _fallbackCourses().firstWhere(
      (c) => c.id.toString() == courseId.toString(),
      orElse: () => _fallbackCourses().first,
    );
  }

  static Future<CourseItem?> createCourse({
    required String title,
    required String description,
    String thumbnailUrl = '',
    PlatformFile? thumbnailFile,
  }) async {
    try {
      if (thumbnailFile != null) {
        final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
        request.fields['title'] = title;
        request.fields['description'] = description;
        if (thumbnailUrl.isNotEmpty) {
          request.fields['thumbnailUrl'] = thumbnailUrl;
        }
        request.files.add(
          await _createMultipartFile('thumbnail', thumbnailFile),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['course'] != null) {
            return CourseItem.fromJson(data['course'] as Map<String, dynamic>);
          }
        }
      } else {
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'description': description,
            'thumbnailUrl': thumbnailUrl,
          }),
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['course'] != null) {
            return CourseItem.fromJson(data['course'] as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      print('[CoursesApi] Error creating course: $e');
    }
    return CourseItem(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl.isNotEmpty
          ? thumbnailUrl
          : 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
      isPublished: true,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  static Future<CourseVideo?> addVideoToCourse({
    required dynamic courseId,
    required String title,
    required String description,
    String? thumbnailUrl,
    String? videoUrl,
    PlatformFile? videoFile,
    PlatformFile? thumbnailFile,
  }) async {
    try {
      if (videoFile != null || thumbnailFile != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/$courseId/videos'),
        );
        request.fields['title'] = title;
        request.fields['description'] = description;
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
          request.fields['thumbnailUrl'] = thumbnailUrl;
        }
        if (videoUrl != null && videoUrl.isNotEmpty) {
          request.fields['videoUrl'] = videoUrl;
        }

        if (videoFile != null) {
          request.files.add(await _createMultipartFile('video', videoFile));
        }
        if (thumbnailFile != null) {
          request.files.add(
            await _createMultipartFile('thumbnail', thumbnailFile),
          );
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['video'] != null) {
            return CourseVideo.fromJson(data['video'] as Map<String, dynamic>);
          }
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl/$courseId/videos'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'description': description,
            'thumbnailUrl': thumbnailUrl ?? '',
            'videoUrl': videoUrl ?? '',
          }),
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['video'] != null) {
            return CourseVideo.fromJson(data['video'] as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      print('[CoursesApi] Error adding video: $e');
    }
    final bunnyId = 'b_${DateTime.now().millisecondsSinceEpoch}';
    return CourseVideo(
      id: DateTime.now().millisecondsSinceEpoch,
      courseId: courseId,
      title: title,
      description: description,
      bunnyVideoId: bunnyId,
      playUrl: 'https://vz-d51ed155-bdd.b-cdn.net/$bunnyId/play',
      iframeUrl: 'https://iframe.mediadelivery.net/embed/754518/$bunnyId',
      hlsUrl: 'https://vz-d51ed155-bdd.b-cdn.net/$bunnyId/playlist.m3u8',
      thumbnailUrl: thumbnailUrl ?? '',
    );
  }

  static Future<bool> deleteVideoFromCourse({
    required dynamic courseId,
    required dynamic videoId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$courseId/videos/$videoId'),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[CoursesApi] Error deleting video: $e');
      return false;
    }
  }

  static Future<CourseMaterial?> addMaterialToCourse({
    required dynamic courseId,
    required String title,
    required String filePath,
    String fileType = 'pdf',
    PlatformFile? materialFile,
  }) async {
    try {
      if (materialFile != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/$courseId/materials'),
        );
        request.fields['title'] = title;
        if (filePath.isNotEmpty) request.fields['filePath'] = filePath;
        request.fields['fileType'] = fileType;
        request.files.add(await _createMultipartFile('material', materialFile));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['material'] != null) {
            return CourseMaterial.fromJson(
              data['material'] as Map<String, dynamic>,
            );
          }
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl/$courseId/materials'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'filePath': filePath,
            'fileType': fileType,
          }),
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['material'] != null) {
            return CourseMaterial.fromJson(
              data['material'] as Map<String, dynamic>,
            );
          }
        }
      }
    } catch (e) {
      print('[CoursesApi] Error adding material: $e');
    }
    return CourseMaterial(
      id: DateTime.now().millisecondsSinceEpoch,
      courseId: courseId,
      title: title,
      filePath: filePath,
      fileType: fileType,
      fileSizeKb: 1024,
    );
  }

  static List<CourseItem> _fallbackCourses() => [
    CourseItem(
      id: 1,
      title: 'Applied Cyber Security & Network Defense',
      description:
          'Comprehensive curriculum covering ethical hacking, network defense, perimeter security, and threat analysis.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
      isPublished: true,
      isEnrolled: true,
      progressPercentage: 65,
      daysLeft: 45,
      createdAt: DateTime.now().toIso8601String(),
      videos: [
        CourseVideo(
          id: 101,
          courseId: 1,
          title: '01. Introduction to Threat Vectors',
          description: 'Perimeter Security Foundations',
          bunnyVideoId: '754518-video-1',
          playUrl: 'https://vz-d51ed155-bdd.b-cdn.net/754518-video-1/play',
          iframeUrl:
              'https://iframe.mediadelivery.net/embed/754518/754518-video-1',
          hlsUrl:
              'https://vz-d51ed155-bdd.b-cdn.net/754518-video-1/playlist.m3u8',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
          durationSeconds: 0,
          watchedSeconds: 1455,
          percentageWatched: 100,
          isCompleted: true,
        ),
        CourseVideo(
          id: 102,
          courseId: 1,
          title: '02. Cryptographic Protocols & Handshake',
          description: 'Handshake Architectures & Ciphers',
          bunnyVideoId: '754518-video-2',
          playUrl: 'https://vz-d51ed155-bdd.b-cdn.net/754518-video-2/play',
          iframeUrl:
              'https://iframe.mediadelivery.net/embed/754518/754518-video-2',
          hlsUrl:
              'https://vz-d51ed155-bdd.b-cdn.net/754518-video-2/playlist.m3u8',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
          durationSeconds: 0,
          watchedSeconds: 2330,
          percentageWatched: 100,
          isCompleted: true,
        ),
        CourseVideo(
          id: 103,
          courseId: 1,
          title: '03. Firewall Configurations & Stateful Inspection',
          description: 'Stateful vs. Stateless Rules',
          bunnyVideoId: '754518-video-3',
          playUrl: 'https://vz-d51ed155-bdd.b-cdn.net/754518-video-3/play',
          iframeUrl:
              'https://iframe.mediadelivery.net/embed/754518/754518-video-3',
          hlsUrl:
              'https://vz-d51ed155-bdd.b-cdn.net/754518-video-3/playlist.m3u8',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
          durationSeconds: 0,
          watchedSeconds: 2530,
          percentageWatched: 100,
          isCompleted: true,
        ),
        CourseVideo(
          id: 104,
          courseId: 1,
          title: '04. Penetration Testing & Vulnerability Assessment',
          description: 'Offensive Scanning & Frameworks',
          bunnyVideoId: '754518-video-4',
          playUrl: 'https://vz-d51ed155-bdd.b-cdn.net/754518-video-4/play',
          iframeUrl:
              'https://iframe.mediadelivery.net/embed/754518/754518-video-4',
          hlsUrl:
              'https://vz-d51ed155-bdd.b-cdn.net/754518-video-4/playlist.m3u8',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
          durationSeconds: 0,
          watchedSeconds: 5,
          percentageWatched: 16,
          isCompleted: false,
        ),
      ],
      materials: [
        CourseMaterial(
          id: 201,
          courseId: 1,
          title: 'Lecture 04 - Network Security Notes & CVSS Scoring',
          filePath:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          fileType: 'pdf',
          fileSizeKb: 1024,
        ),
      ],
    ),
    CourseItem(
      id: 2,
      title: 'Ethical Hacking & Vulnerability Assessment',
      description:
          'Master penetration testing methodologies, scanners, exploit development, and defense.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600',
      isPublished: true,
      isEnrolled: false,
      createdAt: DateTime.now().toIso8601String(),
    ),
    CourseItem(
      id: 3,
      title: 'Cloud Security Fundamentals & IAM',
      description:
          'Learn identity access management, cloud security architecture, and compliance.',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600',
      isPublished: true,
      isEnrolled: false,
      createdAt: DateTime.now().toIso8601String(),
    ),
  ];
}
