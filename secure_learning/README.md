# Secure Learning live lecture sample

This sample has two intentionally hard-coded demo accounts:

- Student: username `admin`, password `admin`
- Admin: username `Admin`, password `Admin`

## Run the signaling backend

```powershell
cd server
npm install
npm start
```

The Node.js WebSocket server runs on port `8080` and relays lecture notifications plus WebRTC signaling messages. It does not store users or media.

If port `8080` is already occupied, do not start a second copy. The existing server is already usable. Alternatively, start another copy with `PORT=8081 npm run start:custom` and use the same port in Flutter:

```powershell
$env:PORT=8081
npm run start:custom
flutter run --dart-define=SIGNALING_URL=ws://10.0.2.2:8081
```

## Run Flutter

```powershell
flutter run
```

The default signaling URL is `ws://10.0.2.2:8080` for an Android emulator. For an iOS simulator or a physical device, pass the host machine's reachable address:

```powershell
flutter run --dart-define=SIGNALING_URL=ws://YOUR_COMPUTER_IP:8080
```

Open the app twice: sign in as admin on one instance, sign in as student on the other, start the lecture from the admin dashboard, then tap `Join` on the student notification. The admin camera stream is sent directly to the student through WebRTC.

This is a testing sample only. Credentials, authentication, lecture state, and authorization must be moved to a real backend before production use.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
