import { Router } from 'express';
import { adminHeartbeat, adminLogin, getProfile, login, refresh, resendEmail, signup, verifyEmail } from './auth.controller.js';
import { requireAuth } from '../../middleware/auth.middleware.js';

const router = Router();

router.post('/signup', signup);
router.post('/verify-email', verifyEmail);
router.post('/resend-email', resendEmail);
router.post('/login', login);
router.get('/me', requireAuth, getProfile);
router.post('/admin-login', adminLogin);
router.post('/admin-heartbeat', requireAuth, adminHeartbeat);
router.post('/refresh', refresh);

export default router;

