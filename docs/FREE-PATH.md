# Free path — no FlutterFlow paid plan, no Expo credits

## What we use instead

| Need | Free solution |
|------|----------------|
| Mobile app | **Flutter** in `SpeakEasyReports/mobile/` (100% free, open source) |
| Build Android APK | `BUILD-Android.bat` on your Windows PC (free) |
| Build iPhone IPA | See iPhone options below |
| PC sync server | `SpeakEasy-PC.bat` (already built) |
| Voice-to-text | `speech_to_text` package (on-device, no cloud fees) |

## Android (easiest, completely free)

1. Enable **Developer options** + **USB debugging** on your Android phone
2. Install [Android Studio](https://developer.android.com/studio) once (free) — only needed for SDK
3. Double-click **`BUILD-Android.bat`**
4. Install the APK on your phone

## iPhone on Windows (no paid FlutterFlow)

You **cannot** build iOS apps on Windows without a cloud Mac. Free options:

1. **Keep your last InspectPro v3.2.1 build** on iPhone if still installed — PC sync still works with SpeakEasy PC server (same API).

2. **FlutterFlow FREE plan** (no API token): build the UI manually in the browser at app.flutterflow.io — free tier allows project creation; export/deploy limits apply. No paid upgrade needed for basic use.

3. **Codemagic free tier** — 500 build minutes/month for iOS (connect GitHub repo).

4. **Borrow a Mac** for one afternoon — `flutter build ipa` with free Apple ID (7-day install) or paid $99/year developer account.

## Recommended for you right now

- **PC:** `SpeakEasy-PC.bat` ✓
- **Phone (Android):** `BUILD-Android.bat` → install APK
- **Phone (iPhone):** keep existing InspectPro app OR use FlutterFlow free UI manually while we finish the Flutter app

The Flutter app in this folder is the **permanent free replacement** for both Expo and paid FlutterFlow API.