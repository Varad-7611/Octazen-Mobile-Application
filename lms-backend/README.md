# LMS backend

## Supabase setup

1. Run `prisma/student.sql` in the Supabase SQL editor.
2. Set `SUPABASE_SERVICE_ROLE_KEY` in `.env` to the project's service-role key. Keep this key on the backend only.
3. Replace the JWT placeholder values in `.env` with long random secrets.
4. Start the API with `npm run dev`.

The API exposes `POST /api/auth/signup` and `POST /api/auth/login`. The Flutter app defaults to `http://10.0.2.2:5000/api` for an Android emulator. Use `--dart-define=API_BASE_URL=http://<computer-ip>:5000/api` for a physical device.