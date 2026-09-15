import 'dotenv/config';
import crypto from 'node:crypto';
import nodemailer from 'nodemailer';

const otpSecret = process.env.OTP_SECRET?.trim();

function hashOtp(username, code) {
  return crypto
    .createHmac('sha256', otpSecret ?? '')
    .update(`${username}:${code}`)
    .digest('hex');
}

function mailTransport() {
  const password = process.env.SMTP_PASSWORD?.replace(/\s/g, '');
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT ?? 587),
    secure: Number(process.env.SMTP_PORT ?? 587) === 465,
    auth: { user: process.env.SMTP_USERNAME, pass: password },
  });
}

export function createOtp(username) {
  const code = crypto.randomInt(1000, 10000).toString();
  return {
    code,
    hash: hashOtp(username, code),
    expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
  };
}

export function verifyOtp(username, code, expectedHash) {
  const actual = Buffer.from(hashOtp(username, code));
  const expected = Buffer.from(expectedHash);
  return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
}

export async function sendOtpEmail(email, code) {
  try {
    await mailTransport().sendMail({
    from: process.env.SMTP_FROM_EMAIL ?? process.env.SMTP_USERNAME,
    to: email,
    subject: 'Your EduTrust verification code',
    text: `Your EduTrust verification code is ${code}. It expires in 10 minutes.`,
    html: `<p>Your EduTrust verification code is:</p><h2>${code}</h2><p>This code expires in 10 minutes.</p>`,
    });
  } catch (error) {
    if (error.responseCode === 535) {
      const smtpError = new Error(
        'Email delivery is not configured. Use a valid Gmail App Password in SMTP_PASSWORD.',
      );
      smtpError.statusCode = 503;
      throw smtpError;
    }
    throw error;
  }
}