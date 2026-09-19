import 'dotenv/config';
import app from './app.js';

const port = Number(process.env.PORT ?? 5000);
const host = process.env.HOST ?? '0.0.0.0';

app.listen(port, host, () => {
  console.log(`LMS backend listening on http://${host}:${port}`);
});
