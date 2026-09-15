import { Router } from 'express';
import { login, refresh, resendEmail, signup, verifyEmail } from './auth.controller.js';

const router = Router();

router.post('/signup', signup);
router.post('/verify-email', verifyEmail);
router.post('/resend-email', resendEmail);
router.post('/login', login);
router.post('/refresh', refresh);

export default router;
