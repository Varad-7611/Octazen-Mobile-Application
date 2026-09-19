# LMS backend

## Supabase setup

1. Run `prisma/student.sql` in the Supabase SQL editor.
2. Run `prisma/admin_presence.sql` in the Supabase SQL editor to enable the admin presence record and Realtime publication.
3. Set `SUPABASE_SERVICE_ROLE_KEY` in `.env` to the project's service-role key. Keep this key on the backend only.
4. Replace the JWT placeholder values in `.env` with long random secrets.
5. Start the API with `npm run dev`.

The API exposes `POST /api/auth/signup`, `POST /api/auth/login`, and `POST /api/auth/admin-login`. The admin credentials are read from `ADMIN_USERNAME` and `ADMIN_PASSWORD`; the admin dashboard sends a JWT-protected heartbeat to `POST /api/auth/admin-heartbeat` every 20 seconds. The Flutter app defaults to `http://10.0.2.2:5000/api` for an Android emulator. Use `--dart-define=API_BASE_URL=http://<computer-ip>:5000/api` for a physical device.