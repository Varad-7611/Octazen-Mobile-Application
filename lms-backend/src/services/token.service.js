import jwt from 'jsonwebtoken';

function studentClaims(student, tokenType) {
  return {
    sub: String(student.id),
    role: 'student',
    username: student.username,
    tokenType,
  };
}

function adminClaims(username, tokenType) {
  return {
    sub: `admin:${username}`,
    role: 'admin',
    username,
    tokenType,
  };
}

export function signAccessToken(student) {
  return jwt.sign(
    studentClaims(student, 'access'),
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: process.env.JWT_ACCESS_EXPIRY ?? '15m' },
  );
}

export function signRefreshToken(student) {
  return jwt.sign(
    studentClaims(student, 'refresh'),
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRY ?? '30d' },
  );
}

export function signAdminAccessToken(username) {
  return jwt.sign(
    adminClaims(username, 'access'),
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: process.env.JWT_ACCESS_EXPIRY ?? '15m' },
  );
}

export function signAdminRefreshToken(username) {
  return jwt.sign(
    adminClaims(username, 'refresh'),
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRY ?? '30d' },
  );
}

export function verifyAccessToken(token) {
  const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
  if (payload.tokenType !== 'access') {
    throw new Error('Invalid access token type.');
  }
  return payload;
}

export function verifyRefreshToken(token) {
  const payload = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  if (payload.tokenType !== 'refresh') {
    throw new Error('Invalid refresh token type.');
  }
  return payload;
}
