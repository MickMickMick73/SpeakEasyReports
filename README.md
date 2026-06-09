# SpeakEasy Reports

Migration of **InspectPro Mobile v3.2.1** to a **free Flutter mobile app** + polished **Windows desktop** app for PC sync.

Original Expo projects are **not modified**.

## No paid FlutterFlow token needed

The paid FlutterFlow API token is **not required**. The mobile app lives in **`mobile/`** as standard Flutter code — build APKs on your PC for free.

| Need | Free solution |
|------|----------------|
| Mobile app | `mobile/` Flutter project |
| Android APK | Double-click **`BUILD-Android.bat`** |
| PC sync server | **`SpeakEasy-PC.bat`** |
| Voice-to-text | On-device `speech_to_text` (no cloud fees) |

See **[docs/FREE-PATH.md](docs/FREE-PATH.md)** for iPhone options and full details.

## Folder layout

```
SpeakEasyReports/
├── BUILD-Android.bat     ← Build APK (free, no account upgrade)
├── SpeakEasy-PC.bat      ← Desktop app + sync server
├── api/                  ← Node sync server (port 3001)
├── desktop/              ← Electron PC app
├── mobile/               ← Flutter app (replaces FlutterFlow API path)
├── docs/                 ← Guides + API contract
├── flutterflow/          ← Optional Dart stubs (manual FF UI only)
└── reports/              ← Generated reports (created on first run)
```

## Quick start (PC)

1. Install [Node.js](https://nodejs.org) if needed
2. Double-click **`SpeakEasy-PC.bat`**
3. Desktop app opens → copy **API URL** to phone Settings
4. Finish inspection on phone → **Push to PC**

## Quick start (Android phone)

1. Enable **Developer options** + **USB debugging** on your phone
2. Install [Android Studio](https://developer.android.com/studio) once (free) — for Android SDK
3. Double-click **`BUILD-Android.bat`**
4. Install `mobile/build/app/outputs/flutter-apk/app-release.apk` on your phone
5. Settings → paste PC API URL (e.g. `http://192.168.x.x:3001`)

## iPhone (no paid FlutterFlow)

- **Keep InspectPro v3.2.1** on iPhone if still installed — same PC sync API works with SpeakEasy PC
- Or use FlutterFlow **free web UI** manually (no API token) — see `docs/FLUTTERFLOW-GUIDE.md`
- Or cloud Mac build via Codemagic free tier — see `docs/FREE-PATH.md`

## Feature parity target

| Feature | Source (v3) | Flutter `mobile/` |
|---------|-------------|-------------------|
| Job details + Speak | SetupScreen | setup_screen.dart |
| Photo / video inspect | InspectScreen | inspect_screen.dart |
| Live captions | useRecordingTranscription | speech during video |
| Push to PC | syncService | sync_service.dart |
| PC Whisper on video | api videoTranscription | Same API |
| History / Settings | History + Settings | Same flow |

## Docs

- [Free path (no paid accounts)](docs/FREE-PATH.md)
- [Migration plan](docs/MIGRATION-PLAN.md)
- [FlutterFlow guide (optional manual UI)](docs/FLUTTERFLOW-GUIDE.md)
- [Data models](docs/DATA-MODELS.md)
- [API contract](docs/API-CONTRACT.md)