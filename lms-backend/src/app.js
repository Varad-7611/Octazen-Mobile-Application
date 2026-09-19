import cors from 'cors';
import cookieParser from 'cookie-parser';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import authRouter from './modules/auth/auth.routes.js';
import courseRouter from './modules/course/course.routes.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

app.use(cors({ origin: true, credentials: true }));
app.use(cookieParser());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/health', (_request, response) => response.json({ status: 'ok' }));
app.use('/api/auth', authRouter);
app.use('/api/courses', courseRouter);

app.use((error, _request, response, _next) => {
  console.error(error);
  response.status(error.statusCode ?? 500).json({
    message: error.message ?? 'Internal server error',
  });
});

export default app;
