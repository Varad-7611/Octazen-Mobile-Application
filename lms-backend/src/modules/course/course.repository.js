import dotenv from 'dotenv';
dotenv.config();

const databaseUrl = process.env.DATABASE_URL?.trim();
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
const baseUrl = databaseUrl?.replace(/\/Student\/?$/, '') || 'https://cqmrbxkodgzhmnextnex.supabase.co/rest/v1';

import { getBunnyStreamUrls, getBunnyVideoDetails } from '../../services/bunny.service.js';

function getHeaders(prefer) {
    return {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        'Content-Type': 'application/json',
        ...(prefer ? { Prefer: prefer } : {}),
    };
}

async function supabaseRequest(endpoint, options = {}) {
    const url = `${baseUrl}/${endpoint}`;
    const response = await fetch(url, {
        ...options,
        headers: { ...getHeaders(options.prefer), ...(options.headers ?? {}) },
    });

    const body = await response.json().catch(() => null);
    if (!response.ok) {
        console.error(`[CourseRepository] Supabase error on ${endpoint} (${response.status}):`, body);
        const error = new Error(body?.message ?? body?.hint ?? 'Supabase database query failed.');
        error.statusCode = response.status >= 500 ? 502 : response.status;
        throw error;
    }
    return body;
}

import fs from 'fs';
import path from 'path';

// Persistent per-student store in lms-backend/data/student_store.json
const STORE_DIR = path.resolve(process.cwd(), 'data');
const STORE_PATH = path.join(STORE_DIR, 'student_store.json');

function loadStudentStore() {
    try {
        if (fs.existsSync(STORE_PATH)) {
            const raw = fs.readFileSync(STORE_PATH, 'utf-8');
            return JSON.parse(raw);
        }
    } catch (e) {
        console.warn('[CourseRepository] Error reading student_store.json:', e.message);
    }
    return {
        enrollments: {
            'default_student': [1],
            '1': [1],
        },
        videoProgress: {},
    };
}

let studentStore = loadStudentStore();

// Bunny reports a video's final duration only after encoding. Cache successful
// lookups briefly so a course page does not make one API call per rebuild.
const durationCache = new Map();
const DURATION_CACHE_TTL_MS = 5 * 60 * 1000;

function saveStudentStore() {
    try {
        if (!fs.existsSync(STORE_DIR)) {
            fs.mkdirSync(STORE_DIR, { recursive: true });
        }
        fs.writeFileSync(STORE_PATH, JSON.stringify(studentStore, null, 2), 'utf-8');
    } catch (e) {
        console.warn('[CourseRepository] Error saving student_store.json:', e.message);
    }
}

function getStudentKey(studentId) {
    if (!studentId) return 'default_student';
    return String(studentId);
}

function getStudentEnrolledSet(studentId) {
    const key = getStudentKey(studentId);
    const list = studentStore.enrollments[key] || [];
    return new Set(list.map(id => parseInt(id, 10)));
}

// Memory fallback store for smooth operation if Supabase table is empty or loading
const inMemoryCourses = [
    {
        id: 1,
        title: 'Applied Cyber Security & Network Defense',
        description: 'Comprehensive curriculum covering ethical hacking, network defense, perimeter security, and threat analysis.',
        thumbnail_url: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
        is_published: true,
        display_order: 1,
        created_at: new Date().toISOString(),
        videos: [
            {
                id: 101,
                course_id: 1,
                title: '01. Introduction to Threat Vectors',
                description: 'Perimeter Security Foundations',
                bunny_video_id: '754518-video-1',
                bunny_library_id: '754518',
                duration_seconds: 0,
                thumbnail_url: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
                status: 'ready',
                is_active: true,
            },
            {
                id: 102,
                course_id: 1,
                title: '02. Cryptographic Protocols & Handshake',
                description: 'Handshake Architectures & Ciphers',
                bunny_video_id: '754518-video-2',
                bunny_library_id: '754518',
                duration_seconds: 0,
                thumbnail_url: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
                status: 'ready',
                is_active: true,
            },
            {
                id: 103,
                course_id: 1,
                title: '03. Firewall Configurations & Stateful Inspection',
                description: 'Stateful vs. Stateless Rules',
                bunny_video_id: '754518-video-3',
                bunny_library_id: '754518',
                duration_seconds: 0,
                thumbnail_url: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
                status: 'ready',
                is_active: true,
            },
            {
                id: 104,
                course_id: 1,
                title: '04. Penetration Testing & Vulnerability Assessment',
                description: 'Offensive Scanning & Frameworks',
                bunny_video_id: '754518-video-4',
                bunny_library_id: '754518',
                duration_seconds: 0,
                thumbnail_url: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=600',
                status: 'ready',
                is_active: true,
            },
        ],
        materials: [
            {
                id: 201,
                course_id: 1,
                title: 'Lecture 04 - Network Security Notes & CVSS Scoring',
                file_path: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                file_type: 'pdf',
                file_size_kb: 1024,
            },
        ],
    },
    {
        id: 2,
        title: 'Ethical Hacking & Vulnerability Assessment',
        description: 'Master penetration testing methodologies, vulnerability scanners, exploit development, and defense.',
        thumbnail_url: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600',
        is_published: true,
        display_order: 2,
        created_at: new Date().toISOString(),
        videos: [],
        materials: [],
    },
];

export async function createCourse({ title, description, thumbnailUrl }) {
    try {
        const rows = await supabaseRequest('courses', {
            method: 'POST',
            prefer: 'return=representation',
            body: JSON.stringify({
                title,
                description: description || '',
                thumbnail_url: thumbnailUrl || 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
                is_published: true,
                display_order: 1,
                created_by: '00000000-0000-0000-0000-000000000000',
            }),
        });
        if (rows && rows[0]) return rows[0];
    } catch (err) {
        console.warn('[CourseRepository] Supabase save course failed, using memory store:', err.message);
    }

    const newCourse = {
        id: inMemoryCourses.length + 1,
        title,
        description: description || '',
        thumbnail_url: thumbnailUrl || 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
        is_published: true,
        display_order: inMemoryCourses.length + 1,
        created_at: new Date().toISOString(),
        videos: [],
        materials: [],
    };
    inMemoryCourses.push(newCourse);
    return newCourse;
}

async function resolveVideoDuration(video) {
    const storedDuration = Number(video.duration_seconds ?? video.durationSeconds ?? 0);
    const rawId = video.bunny_video_id || video.bunnyVideoId || '';
    const libraryId = video.bunny_library_id || video.bunnyLibraryId;
    const isLocalOrFullUrl = rawId.startsWith('http://') || rawId.startsWith('https://') || rawId.startsWith('/uploads');

    if (isLocalOrFullUrl || !rawId) return storedDuration > 0 ? storedDuration : 0;

    const cacheKey = `${libraryId || ''}:${rawId}`;
    const cached = durationCache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) return cached.duration;

    const details = await getBunnyVideoDetails(rawId, libraryId);
    const duration = Number(details?.durationSeconds ?? 0);
    if (duration > 0) {
        durationCache.set(cacheKey, { duration, expiresAt: Date.now() + DURATION_CACHE_TTL_MS });
        if (duration !== storedDuration) {
            // Keep the database's canonical video metadata current. Failure here
            // should never prevent a student from viewing the course.
            supabaseRequest(`videos?id=eq.${video.id}`, {
                method: 'PATCH',
                prefer: 'return=minimal',
                body: JSON.stringify({ duration_seconds: duration }),
            }).catch((err) => console.warn('[CourseRepository] Could not persist Bunny duration:', err.message));

            for (const course of inMemoryCourses) {
                const localVideo = course.videos?.find((item) => String(item.id) === String(video.id));
                if (localVideo) localVideo.duration_seconds = duration;
            }
        }
        return duration;
    }

    // Encoding may still be in progress. Do not invent a 30-second duration.
    return storedDuration > 0 ? storedDuration : 0;
}

async function getWatchProgress(studentId, videoId) {
    const studentKey = getStudentKey(studentId);
    const numericStudentId = Number(studentKey);
    if (Number.isInteger(numericStudentId) && numericStudentId > 0) {
        try {
            const rows = await supabaseRequest(
                `watch_progress?select=*&student_id=eq.${numericStudentId}&video_id=eq.${videoId}&limit=1`,
            );
            const progress = rows?.[0];
            if (progress) {
                return {
                    watchedSeconds: Math.max(0, Number(progress.last_position_seconds ?? 0)),
                    percentage: Math.max(0, Number(progress.watched_percentage ?? 0)),
                    completed: progress.is_completed === true,
                };
            }
            return null;
        } catch (error) {
            console.warn('[CourseRepository] Supabase watch progress lookup failed:', error.message);
        }
    }

    return studentStore.videoProgress[studentKey]?.[videoId] || null;
}

async function enrichVideo(video, studentId) {
    if (!video) return video;
    const rawId = video.bunny_video_id || video.bunnyVideoId || '';
    const libId = video.bunny_library_id || video.bunnyLibraryId || '754518';
    const isLocalOrFullUrl = rawId.startsWith('http://') || rawId.startsWith('https://') || rawId.startsWith('/uploads');

    let bunnyUrls;
    if (isLocalOrFullUrl) {
        bunnyUrls = {
            playUrl: rawId,
            iframeUrl: rawId,
            hlsUrl: rawId,
        };
    } else {
        bunnyUrls = getBunnyStreamUrls(rawId || 'demo', libId);
    }

    const vId = parseInt(video.id, 10);
    const videoDuration = await resolveVideoDuration(video);

    const progress = await getWatchProgress(studentId, vId);
    const prog = progress || {
        watchedSeconds: video.watchedSeconds ?? 0,
        totalSeconds: videoDuration,
        percentage: video.percentageWatched ?? 0,
        completed: video.isCompleted ?? false,
    };
    const savedWatchedSeconds = Math.max(0, Number(prog.watchedSeconds ?? 0));
    const watchedSeconds = videoDuration > 0
        ? Math.min(savedWatchedSeconds, videoDuration)
        : savedWatchedSeconds;

    return {
        ...video,
        ...bunnyUrls,
        // Duration belongs to the Bunny asset, not a student's saved progress.
        duration_seconds: videoDuration,
        watchedSeconds,
        percentageWatched: videoDuration > 0
            ? Math.min(100, Math.round((watchedSeconds / videoDuration) * 100))
            : 0,
        isCompleted: prog.completed ?? false,
    };
}

export async function getAllCourses(studentId) {
    const enrolledSet = getStudentEnrolledSet(studentId);
    try {
        const courses = await supabaseRequest('courses?select=*&order=created_at.desc');
        if (courses && Array.isArray(courses) && courses.length > 0) {
            for (const c of courses) {
                const videos = await supabaseRequest(`videos?select=*&course_id=eq.${c.id}`).catch(() => []);
                const materials = await supabaseRequest(`study_materials?select=*&course_id=eq.${c.id}`).catch(() => []);
                c.videos = await Promise.all((videos || []).map(v => enrichVideo(v, studentId)));
                c.materials = materials || [];
                c.isEnrolled = enrolledSet.has(parseInt(c.id, 10));
            }
            return courses;
        }
    } catch (err) {
        console.warn('[CourseRepository] Supabase get courses failed:', err.message);
    }
    return Promise.all(inMemoryCourses.map(async (c) => ({
        ...c,
        videos: await Promise.all((c.videos || []).map(v => enrichVideo(v, studentId))),
        isEnrolled: enrolledSet.has(parseInt(c.id, 10)),
    })));
}

export async function getCourseById(courseId, studentId) {
    const numericId = parseInt(courseId, 10);
    const enrolledSet = getStudentEnrolledSet(studentId);
    try {
        const courses = await supabaseRequest(`courses?select=*&id=eq.${courseId}&limit=1`);
        const course = courses?.[0];
        if (course) {
            const videos = await supabaseRequest(`videos?select=*&course_id=eq.${courseId}&order=created_at.asc`).catch(() => []);
            const materials = await supabaseRequest(`study_materials?select=*&course_id=eq.${courseId}&order=id.asc`).catch(() => []);

            return {
                ...course,
                isEnrolled: enrolledSet.has(numericId),
                videos: await Promise.all((videos || []).map(v => enrichVideo(v, studentId))),
                materials: materials || [],
            };
        }
    } catch (err) {
        console.warn('[CourseRepository] Supabase get course by ID failed:', err.message);
    }

    const found = inMemoryCourses.find((c) => c.id === numericId || c.id === String(courseId));
    if (found) {
        return {
            ...found,
            isEnrolled: enrolledSet.has(numericId),
            videos: await Promise.all((found.videos || []).map(v => enrichVideo(v, studentId))),
        };
    }

    const fallback = inMemoryCourses[0];
    return {
        ...fallback,
        isEnrolled: enrolledSet.has(parseInt(fallback.id, 10)),
        videos: await Promise.all((fallback.videos || []).map(v => enrichVideo(v, studentId))),
    };
}

export async function enrollCourse(courseId, studentId) {
    const numericId = parseInt(courseId, 10);
    const sKey = getStudentKey(studentId);

    if (!studentStore.enrollments[sKey]) {
        studentStore.enrollments[sKey] = [];
    }
    if (!studentStore.enrollments[sKey].includes(numericId)) {
        studentStore.enrollments[sKey].push(numericId);
    }
    saveStudentStore();

    // Also attempt Supabase persistent write if table exists
    try {
        await supabaseRequest('student_enrollments', {
            method: 'POST',
            prefer: 'return=representation',
            body: JSON.stringify({
                student_id: sKey,
                course_id: numericId,
            }),
        });
    } catch (e) {
        // Table may not exist or duplicate; local JSON store handled it cleanly
    }

    return { success: true, courseId, studentId: sKey };
}

export async function getEnrolledCourses(studentId) {
    const allCourses = await getAllCourses(studentId);
    const enrolledSet = getStudentEnrolledSet(studentId);

    const enrolled = allCourses.filter(c => enrolledSet.has(parseInt(c.id, 10)));
    return enrolled.map(c => {
        const videos = c.videos || [];
        const completedCount = videos.filter((video) => video.isCompleted).length;
        const totalDuration = videos.reduce(
            (sum, video) => sum + Math.max(0, Number(video.duration_seconds ?? 0)),
            0,
        );
        const totalWatched = videos.reduce(
            (sum, video) => sum + Math.max(0, Number(video.watchedSeconds ?? 0)),
            0,
        );
        const progressPct = totalDuration > 0
            ? Math.min(100, Math.round((totalWatched / totalDuration) * 100))
            : 0;
        return {
            ...c,
            completedVideos: completedCount,
            totalVideos: videos.length,
            progressPercentage: progressPct,
            daysLeft: 45,
            isEnrolled: true,
        };
    });
}

async function findVideoById(videoId) {
    const vId = parseInt(videoId, 10);
    try {
        const rows = await supabaseRequest(`videos?select=*&id=eq.${vId}&limit=1`);
        if (rows?.[0]) return rows[0];
    } catch (err) {
        console.warn('[CourseRepository] Supabase video lookup failed:', err.message);
    }

    for (const course of inMemoryCourses) {
        const video = course.videos?.find((item) => parseInt(item.id, 10) === vId);
        if (video) return video;
    }
    return null;
}

export async function updateVideoProgress({ videoId, watchedSeconds, studentId }) {
    const vId = parseInt(videoId, 10);
    const sKey = getStudentKey(studentId);
    if (!Number.isInteger(vId) || vId <= 0) {
        const error = new Error('Invalid video ID.');
        error.statusCode = 400;
        throw error;
    }

    const video = await findVideoById(vId);
    if (!video) {
        const error = new Error('Video not found.');
        error.statusCode = 404;
        throw error;
    }
    const total = await resolveVideoDuration(video);
    if (total <= 0) {
        const error = new Error('Video duration is not available yet. Bunny Stream may still be encoding it.');
        error.statusCode = 409;
        throw error;
    }

    const requestedPosition = Math.max(0, Math.floor(Number(watchedSeconds) || 0));
    const existing = await getWatchProgress(studentId, vId);
    // A progress write is a checkpoint, so do not allow an out-of-order mobile
    // request to move a student's completed position backwards.
    const watched = Math.min(total, Math.max(existing?.watchedSeconds || 0, requestedPosition));
    const pct = Math.min(100, Math.round((watched / total) * 100));
    const completed = pct >= 90;

    const progressData = {
        videoId: vId,
        studentId: sKey,
        watchedSeconds: watched,
        totalSeconds: total,
        percentage: pct,
        completed,
        updatedAt: new Date().toISOString(),
    };

    const numericStudentId = Number(sKey);
    if (Number.isInteger(numericStudentId) && numericStudentId > 0) {
        try {
            await supabaseRequest('watch_progress?on_conflict=student_id,video_id', {
                method: 'POST',
                prefer: 'resolution=merge-duplicates,return=minimal',
                body: JSON.stringify({
                    student_id: numericStudentId,
                    video_id: vId,
                    last_position_seconds: watched,
                    watched_percentage: pct,
                    is_completed: completed,
                    last_watched_at: progressData.updatedAt,
                }),
            });
        } catch (error) {
            // Keep the local store as a temporary fallback when Supabase is unavailable.
            console.warn('[CourseRepository] Supabase progress save failed:', error.message);
        }
    }

    if (!studentStore.videoProgress[sKey]) {
        studentStore.videoProgress[sKey] = {};
    }
    studentStore.videoProgress[sKey][vId] = progressData;
    saveStudentStore();

    return progressData;
}

export async function deleteVideoFromCourse({ courseId, videoId }) {
    const courseIdNumber = parseInt(courseId, 10);
    const videoIdNumber = parseInt(videoId, 10);
    if (!Number.isInteger(courseIdNumber) || !Number.isInteger(videoIdNumber)) {
        const error = new Error('Invalid course or video ID.');
        error.statusCode = 400;
        throw error;
    }

    let deletedVideo = null;
    try {
        const rows = await supabaseRequest(
            `videos?select=*&id=eq.${videoIdNumber}&course_id=eq.${courseIdNumber}&limit=1`,
        );
        deletedVideo = rows?.[0] || null;
        if (deletedVideo) {
            // Delete dependent rows explicitly. This works even when the database
            // has not been configured with an ON DELETE CASCADE relationship.
            await supabaseRequest(`watch_progress?video_id=eq.${videoIdNumber}`, {
                method: 'DELETE',
                prefer: 'return=minimal',
            });
            await supabaseRequest(`videos?id=eq.${videoIdNumber}&course_id=eq.${courseIdNumber}`, {
                method: 'DELETE',
                prefer: 'return=minimal',
            });
        }
    } catch (error) {
        console.warn('[CourseRepository] Supabase video deletion failed:', error.message);
        const failure = new Error('Unable to delete the video from Supabase.');
        failure.statusCode = 502;
        throw failure;
    }

    const localCourse = inMemoryCourses.find((course) => parseInt(course.id, 10) === courseIdNumber);
    const localVideo = localCourse?.videos?.find((video) => parseInt(video.id, 10) === videoIdNumber);
    if (!deletedVideo && !localVideo) {
        const error = new Error('Video not found in this course.');
        error.statusCode = 404;
        throw error;
    }

    if (localCourse && localVideo) {
        localCourse.videos = localCourse.videos.filter((video) => parseInt(video.id, 10) !== videoIdNumber);
    }
    for (const progressByVideo of Object.values(studentStore.videoProgress)) {
        delete progressByVideo[videoIdNumber];
    }
    saveStudentStore();

    return deletedVideo || localVideo;
}

export async function addVideoToCourse({ courseId, title, description, bunnyVideoId, bunnyLibraryId, thumbnailUrl, durationSeconds }) {
    const numericId = parseInt(courseId, 10);
    try {
        const rows = await supabaseRequest('videos', {
            method: 'POST',
            prefer: 'return=representation',
            body: JSON.stringify({
                course_id: numericId,
                title,
                description: description || '',
                bunny_video_id: bunnyVideoId,
                bunny_library_id: bunnyLibraryId || '754518',
                duration_seconds: durationSeconds || null,
                thumbnail_url: thumbnailUrl || '',
                display_order: 1,
                status: 'ready',
                is_active: true,
            }),
        });
        if (rows && rows[0]) return rows[0];
    } catch (err) {
        console.warn('[CourseRepository] Supabase add video failed:', err.message);
    }

    const course = inMemoryCourses.find((c) => c.id === numericId || c.id === String(courseId));
    const newVideo = {
        id: Date.now(),
        course_id: numericId,
        title,
        description: description || '',
        bunny_video_id: bunnyVideoId,
        bunny_library_id: bunnyLibraryId || '754518',
        duration_seconds: durationSeconds || null,
        thumbnail_url: thumbnailUrl || '',
        status: 'ready',
        is_active: true,
        created_at: new Date().toISOString(),
    };
    if (course) {
        course.videos = course.videos || [];
        course.videos.push(newVideo);
    }
    return newVideo;
}

export async function addMaterialToCourse({ courseId, title, filePath, fileType, fileSizeKb }) {
    const numericId = parseInt(courseId, 10);
    try {
        const rows = await supabaseRequest('study_materials', {
            method: 'POST',
            prefer: 'return=representation',
            body: JSON.stringify({
                course_id: numericId,
                title,
                file_path: filePath,
                file_type: fileType || 'pdf',
                file_size_kb: fileSizeKb || 512,
                display_order: 1,
            }),
        });
        if (rows && rows[0]) return rows[0];
    } catch (err) {
        console.warn('[CourseRepository] Supabase add material failed:', err.message);
    }

    const course = inMemoryCourses.find((c) => c.id === numericId || c.id === String(courseId));
    const newMaterial = {
        id: Date.now(),
        course_id: numericId,
        title,
        file_path: filePath,
        file_type: fileType || 'pdf',
        file_size_kb: fileSizeKb || 512,
    };
    if (course) {
        course.materials = course.materials || [];
        course.materials.push(newMaterial);
    }
    return newMaterial;
}
