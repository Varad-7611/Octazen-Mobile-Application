import { verifyAccessToken } from '../services/token.service.js';

export function requireAuth(request, response, next) {
  const header = request.headers.authorization;
  const token = header?.startsWith('Bearer ')
    ? header.slice(7)
    : request.cookies?.access_token;

  if (!token) {
    return response.status(401).json({ message: 'Access token is required.' });
  }

  try {
    const payload = verifyAccessToken(token);
    request.user = payload;
    return next();
  } catch {
    return response.status(401).json({ message: 'Invalid or expired access token.' });
  }
}

export function requireAdmin(request, response, next) {
  requireAuth(request, response, () => {
    if (request.user?.role !== 'admin') {
      return response.status(403).json({ message: 'Administrator access is required.' });
    }
    return next();
  });
}
