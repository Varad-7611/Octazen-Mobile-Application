import fs from 'fs';
import dotenv from 'dotenv';
dotenv.config();

const LIBRARY_ID = process.env.BUNNY_STREAM_LIBRARY_ID;
const API_KEY = process.env.BUNNY_STREAM_API_KEY;
const CDN_HOSTNAME = process.env.BUNNY_CDN_HOSTNAME;
const BASE_URL = `https://video.bunnycdn.com/library/${LIBRARY_ID}/videos`;

function assertBunnyConfigured() {
    if (!LIBRARY_ID || !API_KEY || !CDN_HOSTNAME) {
        throw new Error('Bunny Stream is not configured. Set BUNNY_STREAM_LIBRARY_ID, BUNNY_STREAM_API_KEY, and BUNNY_CDN_HOSTNAME.');
    }
}

/**
 * Creates a video entry in Bunny Stream.
 * @param {string} title
 * @returns {Promise<{ videoId: string, libraryId: string }>}
 */
export async function createBunnyVideo(title) {
    try {
        assertBunnyConfigured();
        const response = await fetch(BASE_URL, {
            method: 'POST',
            headers: {
                AccessKey: API_KEY,
                'Content-Type': 'application/json',
                accept: 'application/json',
            },
            body: JSON.stringify({ title: title || 'Untitled Video' }),
        });

        const data = await response.json();
        if (!response.ok) {
            throw new Error(data?.message || 'Failed to create Bunny Stream video entry.');
        }

        return {
            videoId: data.guid,
            libraryId: String(LIBRARY_ID),
        };
    } catch (error) {
        console.error('[BunnyService] Error creating video:', error);
        throw error;
    }
}

/**
 * Uploads video binary content or fetches from URL to Bunny Stream.
 * @param {string} videoId
 * @param {Buffer|ArrayBuffer|string} source - Buffer or URL string or file path
 */
export async function uploadBunnyVideo(videoId, source) {
    try {
        assertBunnyConfigured();
        if (typeof source === 'string' && source.startsWith('http')) {
            // Fetch from remote URL
            const response = await fetch(`${BASE_URL}/${videoId}/fetch`, {
                method: 'POST',
                headers: {
                    AccessKey: API_KEY,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ url: source }),
            });
            const resData = await response.json();
            console.log(`[BunnyService] Fetch URL uploaded to Bunny Stream (${videoId}):`, resData);
            return resData;
        } else if (source) {
            let bufferPayload = source;
            if (typeof source === 'string' && fs.existsSync(source)) {
                bufferPayload = fs.readFileSync(source);
            }
            // Upload binary payload
            const response = await fetch(`${BASE_URL}/${videoId}`, {
                method: 'PUT',
                headers: {
                    AccessKey: API_KEY,
                    'Content-Type': 'application/octet-stream',
                },
                body: bufferPayload,
            });
            const resData = await response.json();
            console.log(`[BunnyService] Binary video file uploaded to Bunny Stream (${videoId}):`, resData);
            return resData;
        }
    } catch (error) {
        console.warn('[BunnyService] Error uploading video content:', error.message);
        throw error;
    }
}

/**
 * Gets streaming URLs for a Bunny Stream video ID.
 * @param {string} videoId
 * @param {string} libraryId
 */
export function getBunnyStreamUrls(videoId, libraryId) {
    const libId = libraryId || LIBRARY_ID;
    const cleanVideoId = videoId || '';
    return {
        playUrl: `https://${CDN_HOSTNAME}/${cleanVideoId}/play`,
        iframeUrl: `https://iframe.mediadelivery.net/embed/${libId}/${cleanVideoId}?autoplay=true&loop=false&muted=false&preload=true`,
        hlsUrl: `https://${CDN_HOSTNAME}/${cleanVideoId}/playlist.m3u8`,
        thumbnailUrl: `https://${CDN_HOSTNAME}/${cleanVideoId}/thumbnail.jpg`,
        libraryId: String(libId),
    };
}

/**
 * Retrieves details for a Bunny Stream video entry.
 * @param {string} videoId
 * @param {string} libraryId
 */
export async function getBunnyVideoDetails(videoId, libraryId) {
    const libId = libraryId || LIBRARY_ID;
    const cleanVideoId = videoId || '';
    if (!cleanVideoId) return null;
    try {
        assertBunnyConfigured();
        const response = await fetch(`https://video.bunnycdn.com/library/${libId}/videos/${cleanVideoId}`, {
            headers: {
                AccessKey: API_KEY,
                accept: 'application/json',
            },
        });
        if (response.ok) {
            const data = await response.json();
            return {
                videoId: data.guid,
                title: data.title,
                durationSeconds: data.length ? Math.round(data.length) : 0,
                status: data.status,
                raw: data,
            };
        }
    } catch (err) {
        console.warn('[BunnyService] Error fetching video details:', err.message);
    }
    return null;
}

/** Removes the source/encoded asset from Bunny Stream after it is removed from a course. */
export async function deleteBunnyVideo(videoId, libraryId) {
    const libId = libraryId || LIBRARY_ID;
    if (!videoId) return;
    assertBunnyConfigured();

    const response = await fetch(`https://video.bunnycdn.com/library/${libId}/videos/${videoId}`, {
        method: 'DELETE',
        headers: { AccessKey: API_KEY, accept: 'application/json' },
    });
    if (!response.ok && response.status !== 404) {
        const data = await response.json().catch(() => null);
        throw new Error(data?.message || 'Bunny Stream could not delete the video.');
    }
}

