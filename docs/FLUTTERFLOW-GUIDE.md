# FlutterFlow Build Guide — SpeakEasy Reports

Follow this in order inside **FlutterFlow** (logged in on your PC).  
Goal: full parity with InspectPro Mobile **v3.2.1**.

---

## Step 1 — New project

1. **Create New** → Blank app → **SpeakEasy Reports**
2. **Settings → General**: Portrait only, support tablet
3. **Theme**: Dark default
   - Background `#000000`, Primary `#0A84FF`, Surface `#121212`
   - Font: bold headings (18–24px), body 16–18px
4. **Pubspec dependencies** (Settings → Project Dependencies):

```
speech_to_text: ^7.0.0
permission_handler: ^11.3.0
http: ^1.2.0
crypto: ^3.0.0
shared_preferences: ^2.2.0
path_provider: ^2.1.0
uuid: ^4.0.0
share_plus: ^10.0.0
pdf: ^3.11.0
printing: ^5.13.0
image_picker: ^1.0.0
video_player: ^2.9.0
```

For camera recording, enable FlutterFlow **Camera** / **Video Recording** widget (or custom `camera` package).

---

## Step 2 — App State variables

Create in **App State** (persist with SharedPreferences where noted):

| Variable | Type | Persist |
|----------|------|---------|
| `activeSession` | JSON | yes |
| `sessions` | List\<JSON\> | yes |
| `inspectorName` | String | yes |
| `companyName` | String | yes |
| `companyPhone` | String | yes |
| `companyEmail` | String | yes |
| `defaultEmailSubject` | String | yes |
| `defaultEmailBody` | String | yes |
| `apiBaseUrl` | String | yes |
| `localServerEnabled` | bool | yes |
| `appearanceDark` | bool | yes |
| `useBigKeyboard` | bool | yes |
| `dictationPreview` | String | no |
| `isListening` | bool | no |
| `liveTranscript` | String | no |
| `focusField` | String | no |
| `isRecording` | bool | no |

Session JSON shape — see `DATA-MODELS.md`.

---

## Step 3 — Navigation

### Bottom Navigation (3 tabs)

| Tab | Page | Icon |
|-----|------|------|
| Home | `DashboardPage` | home |
| History | `HistoryPage` | history |
| Settings | `SettingsPage` | settings |

### Home stack (push routes)

```
DashboardPage
  → NewInspectionPage (job type cards: General, Plumbing, Electrical, Building)
  → SetupPage
  → InspectPage
  → ReviewPage
  → DeliverPage
```

Disable back gesture on **InspectPage**.

---

## Step 4 — Screens

### DashboardPage
- Hero: "SpeakEasy Reports"
- Primary button: **New job**
- Stats: active / completed counts from `sessions`
- List: last 5 sessions → tap opens History detail

### NewInspectionPage
- 4 large cards (inspection types from templates)
- On tap: create `activeSession` with new UUID, set `inspectionType`, navigate **SetupPage**

### SetupPage
- Fields: Client name*, Site address*, Email, Job note (multiline)
- **Speak** toggle button:
  - On: Custom Action `startDictation` (continuous, `en_AU`)
  - Append `dictationPreview` to field selected by `focusField`
- **Big keyboard** (optional Custom Widget): QWERTY rows if `useBigKeyboard`
- **Start inspection** → validate name + address → **InspectPage**

### InspectPage
- Top bar: client name + site
- **Camera** widget (rear, video mode)
- While recording: red banner + `liveTranscript` text
- Buttons: **Photo** | **Record/Stop** | **Finish**
- On Record:
  1. Start video recording
  2. After 900ms delay → start speech listen (continuous, on-device)
  3. Update `liveTranscript` on partial/final results
- On Stop: save video path + transcript segments to `activeSession.media`
- **Finish** → **ReviewPage**

### ReviewPage
- Summary cards: job details, findings count, media count
- Button: **Generate report** (Custom Action: build HTML + PDF to app documents)
- Button: **Continue** → **DeliverPage**

### DeliverPage
- **Email report** — `share_plus` / platform mail with PDF
- **Share PDF**
- **Push to PC** — Custom Action `pushSessionToPc` using `apiBaseUrl`
- **New inspection** — clear `activeSession`, go Dashboard

### HistoryPage
- List all `sessions` with sync status chip
- Tap → view summary, retry push if failed

### SettingsPage
- Company profile fields
- Email template fields (show placeholder legend)
- **Office PC URL** + **Test connection** (`GET {apiBaseUrl}/health`)
- Auto-sync toggle
- Dark/light theme toggle
- App version label: SpeakEasy 1.0.0

---

## Step 5 — Custom Actions (paste from `flutterflow/custom_actions/`)

1. **push_session_to_pc.dart** — full sync pipeline
2. **start_dictation.dart** — speech_to_text wrapper
3. Add **testApiConnection** — simple GET /health, return bool
4. Add **buildManifest** — JSON from activeSession (mirror `mobile/src/sync/manifest.ts`)
5. Add **generateReport** — HTML template (port from `renderHtml.ts` logic)

In FlutterFlow: **Custom Code → Actions → + Add Action** → paste Dart.

---

## Step 6 — API integration in FlutterFlow

Create **API Group**: `SpeakEasyPC`

| Call | Method | URL |
|------|--------|-----|
| Health | GET | `[apiBaseUrl]/health` |
| Presign | POST | `[apiBaseUrl]/api/uploads/presign` |
| Manifest | POST | `[apiBaseUrl]/api/uploads/manifest` |
| Reports | GET | `[apiBaseUrl]/api/reports` |

File uploads use **Custom Action** PUT (not FF API call) — see `push_session_to_pc.dart`.

---

## Step 7 — Permissions (iOS Info.plist / Android manifest)

FlutterFlow **Permissions** screen:

- Camera
- Microphone
- Speech recognition (iOS)
- Local network (iOS — for LAN API)
- Photo library (optional)

Usage strings:
- "Capture photos and video during inspections."
- "Transcribe your voice into job details and video captions."
- "Connect to your office PC on the local network."

---

## Step 8 — Build without Expo

1. **FlutterFlow → Settings → Mobile Deployment**
2. **iOS**: connect Apple Developer, build IPA (or export to Codemagic)
3. **Android**: build APK — install directly (no Play Store needed)
4. No Expo Go, no EAS credits

---

## Step 9 — Connect to PC

1. Run **SpeakEasy-PC.bat** on Windows
2. Copy API URL or scan QR in Desktop app
3. Phone Settings → paste URL → Test → Push

---

## Browser tip (FlutterFlow on PC)

You can use FlutterFlow in the browser alongside this folder:

- Keep `docs/API-CONTRACT.md` open for endpoint bodies
- Copy Custom Actions from `flutterflow/custom_actions/`
- Use **Preview** mode on a physical phone via USB/Wi‑Fi debugging after APK install

---

## Priority if time is short

1. Setup + Speak ✓  
2. Inspect video + live captions ✓  
3. Push to PC ✓  
4. PDF report ✓  
5. Email share  
6. History + auto-sync  
7. AI polish (optional Groq — skip initially)