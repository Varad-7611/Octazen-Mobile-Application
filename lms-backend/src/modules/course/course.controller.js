import {
    createCourse,
    getAllCourses,
    getCourseById,
    addVideoToCourse,
    addMaterialToCourse,
    enrollCourse,
    getEnrolledCourses,
    updateVideoProgress,
    deleteVideoFromCourse,
} from './course.repository.js';
import {
    createBunnyVideo,
    uploadBunnyVideo,
    getBunnyStreamUrls,
    getBunnyVideoDetails,
    deleteBunnyVideo,
} from '../../services/bunny.service.js';

function getFileUrl(req, file) {
    if (!file) return null;
    const protocol = req.protocol || 'http';
    const host = req.get('host') || 'localhost:5000';
    const relativePath = file.path.replace(/\\/g, '/').split('/uploads/')[1];
    return `${protocol}://${host}/uploads/${relativePath}`;
}

function getStudentId(req) {
    return req.user?.role === 'student' ? req.user.sub : null;
}

export async function getCoursesHandler(req, res, next) {
    try {
        const studentId = getStudentId(req);
        const courses = await getAllCourses(studentId);
        res.json({ success: true, courses });
    } catch (error) {
        next(error);
    }
}

export async function getEnrolledCoursesHandler(req, res, next) {
    try {
        const studentId = getStudentId(req);
        const courses = await getEnrolledCourses(studentId);
        res.json({ success: true, courses });
    } catch (error) {
        next(error);
    }
}

export async function enrollCourseHandler(req, res, next) {
    try {
        const { id } = req.params;
        const studentId = getStudentId(req);
        if (!studentId) {
            return res.status(403).json({ message: 'Only student accounts can enroll in a course.' });
        }
        const result = await enrollCourse(id, studentId);
        res.json({ success: true, ...result });
    } catch (error) {
        next(error);
    }
}

export async function updateVideoProgressHandler(req, res, next) {
    try {
        const { videoId, watchedSeconds } = req.body;
        const studentId = getStudentId(req);
        if (!studentId || req.user?.role !== 'student') {
            return res.status(401).json({ message: 'A signed-in student is required to record video progress.' });
        }
        if (!videoId || !Number.isFinite(Number(watchedSeconds))) {
            return res.status(400).json({ message: 'videoId is required' });
        }
        const progress = await updateVideoProgress({
            videoId,
            watchedSeconds: parseInt(watchedSeconds || 0, 10),
            studentId,
        });
        res.json({ success: true, progress });
    } catch (error) {
        next(error);
    }
}

export async function createCourseHandler(req, res, next) {
    try {
        const { title, description } = req.body;
        let thumbnailUrl = req.body.thumbnailUrl;

        if (req.file) {
            thumbnailUrl = getFileUrl(req, req.file);
        }

        if (!title || !title.trim()) {
            return res.status(400).json({ message: 'Course title is required.' });
        }

        const course = await createCourse({
            title: title.trim(),
            description: description?.trim() || '',
            thumbnailUrl: thumbnailUrl?.trim() || 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
        });

        res.status(201).json({ success: true, course });
    } catch (error) {
        next(error);
    }
}

export async function getCourseDetailsHandler(req, res, next) {
    try {
        const { id } = req.params;
        const studentId = getStudentId(req);
        const course = await getCourseById(id, studentId);
        if (!course) {
            return res.status(404).json({ message: 'Course not found.' });
        }

        // Enhance videos with streaming or uploaded file URLs
        const enhancedVideos = (course.videos || []).map((video) => {
            const rawId = video.bunny_video_id || video.bunnyVideoId || '';
            const isLocalUrl = rawId.startsWith('http://') || rawId.startsWith('https://') || rawId.startsWith('/uploads');

            if (isLocalUrl) {
                return {
                    ...video,
                    playUrl: rawId,
                    iframeUrl: rawId,
                    hlsUrl: rawId,
                };
            }

            const bunnyInfo = getBunnyStreamUrls(
                rawId || 'demo',
                video.bunny_library_id || video.bunnyLibraryId,
            );
            return {
                ...video,
                playUrl: bunnyInfo.playUrl,
                iframeUrl: bunnyInfo.iframeUrl,
                hlsUrl: bunnyInfo.hlsUrl,
            };
        });

        res.json({
            success: true,
            course: {
                ...course,
                videos: enhancedVideos,
            },
        });
    } catch (error) {
        next(error);
    }
}

export async function addVideoHandler(req, res, next) {
    try {
        const { id } = req.params;
        const { title, description } = req.body;
        let thumbnailUrl = req.body.thumbnailUrl;
        let videoUrl = req.body.videoUrl;

        const videoFile = req.files?.video?.[0];
        const thumbnailFile = req.files?.thumbnail?.[0];

        if (thumbnailFile) {
            thumbnailUrl = getFileUrl(req, thumbnailFile);
        }

        if (videoFile) {
            videoUrl = getFileUrl(req, videoFile);
        }

        if (!title || !title.trim()) {
            return res.status(400).json({ message: 'Video title is required.' });
        }

        // Bunny Stream owns playback, encoding, quality selection, and duration.
        let bunnyVideoId = '';
        let bunnyLibraryId = '754518';

        try {
            const bunnyRes = await createBunnyVideo(title.trim());
            bunnyVideoId = bunnyRes.videoId;
            bunnyLibraryId = bunnyRes.libraryId || '754518';

            if (videoFile?.path) {
                console.log(`[AddVideoHandler] Uploading binary video file to Bunny Stream (${bunnyVideoId})...`);
                await uploadBunnyVideo(bunnyVideoId, videoFile.path);
            } else if (videoUrl && videoUrl.startsWith('http')) {
                console.log(`[AddVideoHandler] Fetching remote video URL to Bunny Stream (${bunnyVideoId})...`);
                await uploadBunnyVideo(bunnyVideoId, videoUrl);
            }
        } catch (bunnyErr) {
            console.error('[AddVideoHandler] Bunny Stream upload failed:', bunnyErr);
            bunnyErr.statusCode = 502;
            throw bunnyErr;
        }

        // Save to Supabase Database
        // The length is available once Bunny has finished encoding. Store it when
        // available; course reads will refresh it again while the video is processing.
        const bunnyDetails = await getBunnyVideoDetails(bunnyVideoId, bunnyLibraryId);
        const video = await addVideoToCourse({
            courseId: id,
            title: title.trim(),
            description: description?.trim() || '',
            bunnyVideoId: bunnyVideoId,
            bunnyLibraryId: bunnyLibraryId,
            thumbnailUrl: thumbnailUrl?.trim() || '',
            durationSeconds: bunnyDetails?.durationSeconds || null,
        });

        const bunnyUrls = getBunnyStreamUrls(bunnyVideoId, bunnyLibraryId);

        res.status(201).json({
            success: true,
            video: {
                ...video,
                ...bunnyUrls,
                localVideoUrl: videoUrl,
            },
        });
    } catch (error) {
        next(error);
    }
}

export async function deleteVideoHandler(req, res, next) {
    try {
        const { id: courseId, videoId } = req.params;
        const deletedVideo = await deleteVideoFromCourse({ courseId, videoId });

        try {
            const bunnyVideoId = deletedVideo.bunny_video_id || deletedVideo.bunnyVideoId;
            const bunnyLibraryId = deletedVideo.bunny_library_id || deletedVideo.bunnyLibraryId;
            if (bunnyVideoId && !bunnyVideoId.startsWith('http')) {
                await deleteBunnyVideo(bunnyVideoId, bunnyLibraryId);
            }
        } catch (bunnyError) {
            // The course/video/progress records are already gone. Keep the response
            // successful, but make any orphaned Bunny asset visible in server logs.
            console.warn('[DeleteVideoHandler] Bunny asset deletion failed:', bunnyError.message);
        }

        res.json({ success: true, deletedVideoId: String(videoId) });
    } catch (error) {
        next(error);
    }
}

export async function addMaterialHandler(req, res, next) {
    try {
        const { id } = req.params;
        const { title } = req.body;
        let filePath = req.body.filePath;
        let fileSizeKb = req.body.fileSizeKb ? parseInt(req.body.fileSizeKb, 10) : 512;
        let fileType = req.body.fileType || 'pdf';

        if (req.file) {
            filePath = getFileUrl(req, req.file);
            fileSizeKb = Math.round(req.file.size / 1024);
            const parts = req.file.originalname.split('.');
            if (parts.length > 1) {
                fileType = parts.pop().toLowerCase();
            }
        }

        if (!title || !title.trim()) {
            return res.status(400).json({ message: 'Material title is required.' });
        }

        const material = await addMaterialToCourse({
            courseId: id,
            title: title.trim(),
            filePath: filePath?.trim() || 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            fileType: fileType,
            fileSizeKb: fileSizeKb,
        });

        res.status(201).json({ success: true, material });
    } catch (error) {
        next(error);
    }
}
