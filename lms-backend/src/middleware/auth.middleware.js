import { verifyAccessToken } from '../services/token.service.js';

export function requireAuth(request, response, next) {
  const header = request.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;

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