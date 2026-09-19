import { Router } from 'express';
import {
    getCoursesHandler,
    getEnrolledCoursesHandler,
    enrollCourseHandler,
    updateVideoProgressHandler,
    createCourseHandler,
    getCourseDetailsHandler,
    addVideoHandler,
    deleteVideoHandler,
    addMaterialHandler,
} from './course.controller.js';
import { upload } from '../../middleware/upload.middleware.js';
import { requireAdmin, requireAuth } from '../../middleware/auth.middleware.js';

const router = Router();

router.get('/', requireAuth, getCoursesHandler);
router.get('/enrolled', requireAuth, getEnrolledCoursesHandler);
router.post('/video-progress', requireAuth, updateVideoProgressHandler);
router.post('/:id/enroll', requireAuth, enrollCourseHandler);
router.post('/', requireAdmin, upload.single('thumbnail'), createCourseHandler);
router.get('/:id', requireAuth, getCourseDetailsHandler);
router.post(
    '/:id/videos',
    requireAdmin,
    upload.fields([
        { name: 'video', maxCount: 1 },
        { name: 'thumbnail', maxCount: 1 },
    ]),
    addVideoHandler,
);
router.delete('/:id/videos/:videoId', requireAdmin, deleteVideoHandler);
router.post('/:id/materials', requireAdmin, upload.single('material'), addMaterialHandler);

export default router;
