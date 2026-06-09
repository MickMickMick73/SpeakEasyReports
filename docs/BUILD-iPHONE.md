# Build SpeakEasy Reports for iPhone

Windows **cannot** create an iPhone install file (IPA) locally. This guide uses **Codemagic** (free cloud Mac) to build from the Flutter app in `mobile/`.

**Old InspectPro app:** stop fixing — use **SpeakEasy Link** (`/link`) for PC bridge until the new app is installed.

---

## What you already have working

| Piece | Status |
|-------|--------|
| PC Link server | `SpeakEasy-Link.bat` |
| iPhone Link (Safari) | `http://YOUR-PC-IP:3001/link` |
| Flutter iPhone app code | `mobile/` |
| iOS permissions (camera, mic, LAN) | `mobile/ios/Runner/Info.plist` |

---

## Step 1 — Prepare GitHub (one time)

1. Double-click **`PREPARE-iPhone-Build.bat`**
2. Create a **free GitHub** account if needed: https://github.com/join
3. Create a new **private** repo: e.g. `SpeakEasyReports`
4. Push this folder to GitHub (the bat file prints the commands)

---

## Step 2 — Codemagic (free cloud build)

1. Go to https://codemagic.io/signup
2. Sign up with **GitHub**
3. **Add application** → select your `SpeakEasyReports` repo
4. Codemagic detects **`codemagic.yaml`** → workflow **speakeasy-ios**

### Apple signing (required for iPhone install)

In Codemagic → **Team settings** → **Code signing**:

- **Option A — Apple Developer ($99/year):** best for long-term install + TestFlight
- **Option B — Free Apple ID:** development builds, reinstall every ~7 days

Add your Apple ID and let Codemagic manage certificates, or upload your own.

Update `codemagic.yaml` email under `publishing.email.recipients` to your address.

---

## Step 3 — Run the build

1. In Codemagic, start workflow **SpeakEasy Reports iOS**
2. Wait ~10–20 minutes (first build may download Flutter pods)
3. Download the **`.ipa`** artifact when green

---

## Step 4 — Install on your iPhone

### With Apple Developer account (recommended)

1. Upload IPA to **TestFlight** (Codemagic can automate this if configured)
2. Install **TestFlight** on iPhone
3. Open invite link → install **SpeakEasy Reports**

### Without paid developer (development IPA)

1. Download IPA from Codemagic to your PC
2. Use **Apple Configurator** on a Mac, or a service like **Diawi** / **InstallOnAir** (upload IPA, open link on iPhone)
3. iPhone: **Settings → General → VPN & Device Management** → trust the developer

---

## Step 5 — Connect to PC (same as Link)

1. On PC: **`SpeakEasy-Link.bat`** (keep running)
2. On iPhone app: **Settings** → Office PC URL → `http://192.168.1.110:3001` (your LAN IP)
3. **Test PC connection** → should say Connected
4. Run inspections → **Push to PC**

Link page (`/link`) still works in Safari for quick file/notes bridge.

---

## Bundle ID

`com.speakeasy.speakeasyReports` — do not change unless you update Xcode project + Codemagic signing.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Codemagic signing failed | Add Apple ID in Codemagic code signing |
| App won't open on iPhone | Trust developer in iPhone Settings |
| PC connection fails | Same Wi‑Fi, use `/link` to test first |
| Build fails on pods | Re-run build; Codemagic runs `pod install` automatically |