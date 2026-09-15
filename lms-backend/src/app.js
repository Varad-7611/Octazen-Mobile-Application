import cors from 'cors';
import express from 'express';
import authRouter from './modules/auth/auth.routes.js';

const app = express();

app.use(cors());
app.use(express.json());
app.get('/health', (_request, response) => response.json({ status: 'ok' }));
app.use('/api/auth', authRouter);

app.use((error, _request, response, _next) => {
  console.error(error);
  response.status(error.statusCode ?? 500).json({
    message: error.message ?? 'Internal server error',
  });
});

export default app;
