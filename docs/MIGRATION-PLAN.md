# SpeakEasy Reports — Migration Plan (Expo v3.2.1 → FlutterFlow)

**Source (read-only):** `InspectPro Mobile v3`  
**New project:** `C:\Users\a\Desktop\SpeakEasyReports`  
**Why:** No Expo/EAS build credits — FlutterFlow exports a standalone IPA/APK without Expo Go.

---

## Architecture

| Layer | Technology |
|-------|------------|
| Mobile app | FlutterFlow → Flutter (iOS + Android) |
| Office PC | SpeakEasy Desktop (Electron) + Node API |
| Sync | REST — same API as InspectPro v3 |
| Offline speech | `speech_to_text` on-device (iOS/Android) |
| PC video transcript | Whisper on server after push |

---

## Phase 1 — PC foundation (DONE in this folder)

- [x] `api/` — sync server (presign → upload → manifest)
- [x] `desktop/` — Electron app (connection wizard, QR, reports)
- [x] `SpeakEasy-PC.bat` — one-click launch

---

## Phase 2 — FlutterFlow project setup (you + guide)

1. In FlutterFlow: **Create new project** → name **SpeakEasy Reports**
2. Enable **iOS + Android**, portrait only
3. Add packages (Project Settings → Pubspec Dependencies):
   - `speech_to_text`
   - `permission_handler`
   - `camera` / use FF Camera widget
   - `http`
   - `crypto`
   - `shared_preferences`
   - `path_provider`
   - `pdf` + `printing` (reports)
   - `share_plus`
   - `url_launcher`
   - `uuid`

4. Create **App State** variables (see `DATA-MODELS.md`)

5. Build screens in order (see `FLUTTERFLOW-GUIDE.md`)

---

## Phase 3 — Feature parity checklist

### Navigation
- [ ] Bottom nav: Home | History | Settings
- [ ] Stack: Dashboard → New Job → Setup → Inspect → Review → Deliver

### Setup (job details)
- [ ] Client name*, site address*, email, job note
- [ ] Big custom keyboard widget (optional FF custom widget)
- [ ] Speak button → dictation into focused field
- [ ] On-device speech first (`en_AU`)

### Inspect
- [ ] Camera preview (rear)
- [ ] Photo capture
- [ ] Video record + live caption overlay
- [ ] Photo/video counts
- [ ] Finish → Review

### Review & Deliver
- [ ] Generate HTML + PDF on device
- [ ] Email (share sheet / mailto)
- [ ] Share PDF
- [ ] Push to PC (custom action `push_session_to_pc.dart`)

### Settings
- [ ] Inspector / company profile
- [ ] Email templates with placeholders
- [ ] API URL + test connection (`GET /health`)
- [ ] Auto-sync toggle
- [ ] Dark / light theme
- [ ] Big keyboard toggle

### History
- [ ] Past sessions list
- [ ] Sync status badge
- [ ] Retry push

---

## Phase 4 — Build & deploy (no Expo credits)

1. FlutterFlow → **Deploy** → iOS/Android
2. Download IPA or install via TestFlight (Apple Developer $99/year) OR Android APK (free, sideload)
3. Phone Settings → paste API URL from SpeakEasy Desktop

---

## What we are NOT migrating

- Expo Go / Metro dev workflow
- `whisper-kit-expo` (use PC Whisper after push, or add FF custom `whisper_flutter` later)
- Voice commands / hands-free (removed in v3 by design)
- Screen rotation

---

## Timeline estimate

| Phase | Effort |
|-------|--------|
| PC app + API | Done |
| FF data model + navigation | 1–2 days |
| Setup + speech | 1–2 days |
| Camera + live captions | 2–3 days |
| Reports + deliver | 1–2 days |
| Polish + device testing | 2–3 days |

**Total:** ~1–2 weeks part-time in FlutterFlow UI.

---

## Support files

- `docs/FLUTTERFLOW-GUIDE.md` — screen-by-screen build instructions
- `docs/API-CONTRACT.md` — endpoints for FF API calls
- `docs/DATA-MODELS.md` — App State + Firestore/SQLite schema
- `flutterflow/custom_actions/` — paste into FlutterFlow Custom Code