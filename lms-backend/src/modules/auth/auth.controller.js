import bcrypt from 'bcryptjs';
import {
  activateStudent,
  createStudent,
  deleteStudent,
  findLatestEmailOtp,
  findStudentByLogin,
  findStudentByUsername,
  incrementEmailOtpAttempts,
  markEmailOtpUsed,
  saveEmailOtp,
  updateLastLogin,
  upsertAdminPresence,
} from './student.repository.js';
import { createOtp, sendOtpEmail, verifyOtp } from './otp.service.js';
import {
  signAccessToken,
  signAdminAccessToken,
  signAdminRefreshToken,
  signRefreshToken,
  verifyRefreshToken,
} from '../../services/token.service.js';

function setAuthCookies(response, accessToken, refreshToken) {
  const options = {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
  };

  response.cookie('access_token', accessToken, { ...options, maxAge: 15 * 60 * 1000 });
  response.cookie('refresh_token', refreshToken, { ...options, maxAge: 30 * 24 * 60 * 60 * 1000 });
}

const passwordPattern = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;

function publicStudent(student) {
  return {
    id: student.id,
    fullName: student.full_name,
    mobile: student.mobile,
    email: student.email,
    username: student.username,
  };
}

export async function signup(request, response, next) {
  try {
    const { fullName, mobile, email, username, password, confirmPassword } = request.body;
    const values = [fullName, mobile, email, username, password, confirmPassword];

    if (values.some((value) => typeof value !== 'string' || value.trim() === '')) {
      return response.status(400).json({ message: 'All fields are required.' });
    }
    if (password !== confirmPassword) {
      return response.status(400).json({ message: 'Passwords do not match.' });
    }
    if (!passwordPattern.test(password)) {
      return response.status(400).json({
        message: 'Password must be at least 8 characters and include a number.',
      });
    }
    if (!/^\+?[0-9\s-]{7,20}$/.test(mobile.trim())) {
      return response.status(400).json({ message: 'Enter a valid mobile number.' });
    }

    const normalized = {
      fullName: fullName.trim(),
      mobile: mobile.trim(),
      email: email.trim().toLowerCase(),
      username: username.trim().toLowerCase(),
    };
    const existingStudent = await findStudentByUsername(normalized.username);
    if (existingStudent) {
      if (existingStudent.Is_verify === true) {
        return response.status(409).json({ message: 'That username is already registered.' });
      }

      const otp = createOtp(normalized.username);
      await saveEmailOtp({
        username: normalized.username,
        email: existingStudent.email,
        otpHash: otp.hash,
        expiresAt: otp.expiresAt,
      });
      await sendOtpEmail(existingStudent.email, otp.code);
      return response.status(201).json({
        message: 'A new verification code was sent to your email.',
        requiresVerification: true,
        student: publicStudent(existingStudent),
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const student = await createStudent({ ...normalized, passwordHash });
    try {
      const otp = createOtp(normalized.username);
      await saveEmailOtp({
        username: normalized.username,
        email: normalized.email,
        otpHash: otp.hash,
        expiresAt: otp.expiresAt,
      });
      await sendOtpEmail(normalized.email, otp.code);
    } catch (error) {
      await deleteStudent(normalized.username);
      throw error;
    }
    return response.status(201).json({
      message: 'Verification code sent to your email.',
      requiresVerification: true,
      student: publicStudent(student),
    });
  } catch (error) {
    return next(error);
  }
}

export async function verifyEmail(request, response, next) {
  try {
    const username = request.body.username?.trim().toLowerCase();
    const code = request.body.code?.trim();
    if (!username || !/^\d{4}$/.test(code ?? '')) {
      return response.status(400).json({ message: 'Enter the 4-digit verification code.' });
    }

    const otp = await findLatestEmailOtp(username);
    if (!otp || new Date(otp.expires_at) < new Date()) {
      return response.status(400).json({ message: 'This code has expired. Request a new code.' });
    }
    if (otp.attempts >= 5) {
      return response.status(429).json({ message: 'Too many attempts. Request a new code.' });
    }
    if (!verifyOtp(username, code, otp.otp_hash)) {
      await incrementEmailOtpAttempts(otp.id, otp.attempts);
      return response.status(400).json({ message: 'Incorrect verification code.' });
    }

    await markEmailOtpUsed(otp.id);
    await activateStudent(username);
    return response.json({ message: 'Email verified. Registration complete.' });
  } catch (error) {
    return next(error);
  }
}

export async function resendEmail(request, response, next) {
  try {
    const username = request.body.username?.trim().toLowerCase();
    const student = username ? await findStudentByUsername(username) : null;
    if (!student) return response.status(404).json({ message: 'Student account not found.' });
    const otp = createOtp(username);
    await saveEmailOtp({ username, email: student.email, otpHash: otp.hash, expiresAt: otp.expiresAt });
    await sendOtpEmail(student.email, otp.code);
    return response.json({ message: 'A new verification code was sent.' });
  } catch (error) {
    return next(error);
  }
}

export async function login(request, response, next) {
  try {
    const { username, password } = request.body;
    if (typeof username !== 'string' || typeof password !== 'string' || !username.trim() || !password) {
      return response.status(400).json({ message: 'Username and password are required.' });
    }

    const student = await findStudentByLogin(username.trim().toLowerCase());
    if (
      !student ||
      student.Is_verify !== true ||
      !(await bcrypt.compare(password, student.password_hash))
    ) {
      return response.status(401).json({ message: 'Invalid username or password.' });
    }

    await updateLastLogin(student.username);
    const accessToken = signAccessToken(student);
    const refreshToken = signRefreshToken(student);

    setAuthCookies(response, accessToken, refreshToken);

    return response.json({
      message: 'Login successful.',
      accessToken,
      refreshToken,
      token: accessToken,
      student: publicStudent(student),
    });
  } catch (error) {
    return next(error);
  }
}

export async function adminLogin(request, response, next) {
  try {
    const username = request.body.username?.trim();
    const password = request.body.password;
    if (!username || typeof password !== 'string') {
      return response.status(400).json({ message: 'Username and password are required.' });
    }
    if (username !== process.env.ADMIN_USERNAME || password !== process.env.ADMIN_PASSWORD) {
      return response.status(401).json({ message: 'Invalid admin username or password.' });
    }

    const accessToken = signAdminAccessToken(username);
    const refreshToken = signAdminRefreshToken(username);
    try {
      await upsertAdminPresence({
        username,
        deviceName: request.headers['user-agent'],
      });
    } catch (error) {
      console.warn(`Admin presence unavailable: ${error.message}`);
    }
    setAuthCookies(response, accessToken, refreshToken);
    return response.json({
      message: 'Admin login successful.',
      accessToken,
      refreshToken,
      admin: { username, role: 'admin' },
    });
  } catch (error) {
    return next(error);
  }
}

export async function adminHeartbeat(request, response, next) {
  try {
    if (request.user?.role !== 'admin') {
      return response.status(403).json({ message: 'Admin access is required.' });
    }
    await upsertAdminPresence({
      username: request.user.username,
      deviceName: request.headers['user-agent'],
    });
    return response.json({ online: true, lastSeenAt: new Date().toISOString() });
  } catch (error) {
    return next(error);
  }
}

export async function refresh(request, response, next) {
  try {
    const refreshToken = request.body.refreshToken ?? request.cookies.refresh_token;
    if (typeof refreshToken !== 'string' || !refreshToken) {
      return response.status(400).json({ message: 'Refresh token is required.' });
    }

    const payload = verifyRefreshToken(refreshToken);
    if (typeof payload.username !== 'string') {
      return response.status(401).json({ message: 'Invalid refresh token.' });
    }

    const student = await findStudentByLogin(payload.username);
    if (!student || student.Is_verify !== true) {
      return response.status(401).json({ message: 'Student account is not active.' });
    }

    const accessToken = signAccessToken(student);
    const nextRefreshToken = signRefreshToken(student);
    setAuthCookies(response, accessToken, nextRefreshToken);

    return response.json({
      accessToken,
      refreshToken: nextRefreshToken,
    });
  } catch (error) {
    if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
      return response.status(401).json({ message: 'Invalid or expired refresh token.' });
    }
    return next(error);
  }
}

export async function getProfile(request, response, next) {
  try {
    const username = request.user?.username;
    if (!username) {
      return response.status(401).json({ message: 'Authentication required.' });
    }

    const student = await findStudentByUsername(username);
    if (!student) {
      return response.status(404).json({ message: 'Student profile not found.' });
    }

    return response.json({
      student: publicStudent(student),
    });
  } catch (error) {
    return next(error);
  }
}

