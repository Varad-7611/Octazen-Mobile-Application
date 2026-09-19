import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const uploadsBase = path.join(__dirname, '../../uploads');

const thumbnailsDir = path.join(uploadsBase, 'thumbnails');
const videosDir = path.join(uploadsBase, 'videos');
const materialsDir = path.join(uploadsBase, 'materials');

[uploadsBase, thumbnailsDir, videosDir, materialsDir].forEach((dir) => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

const storage = multer.diskStorage({
    destination: (_req, file, cb) => {
        if (file.fieldname === 'thumbnail') {
            cb(null, thumbnailsDir);
        } else if (file.fieldname === 'video') {
            cb(null, videosDir);
        } else if (file.fieldname === 'material' || file.fieldname === 'file') {
            cb(null, materialsDir);
        } else {
            cb(null, uploadsBase);
        }
    },
    filename: (_req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const ext = path.extname(file.originalname) || '';
        cb(null, uniqueSuffix + ext);
    },
});

export const upload = multer({
    storage,
    limits: {
        fileSize: 500 * 1024 * 1024, // 500MB max limit
    },
});
