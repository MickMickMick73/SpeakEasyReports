# Codemagic — next steps (you have an account)

Git is ready on your PC. Finish these steps in order.

---

## Step 1 — Push to GitHub (5 min)

1. Open https://github.com/new
2. Repository name: **SpeakEasyReports**
3. Visibility: **Private** (recommended)
4. Do **not** add README or .gitignore (we already have them)
5. Click **Create repository**

6. In PowerShell, run (replace `YOUR_GITHUB_USERNAME`):

```powershell
cd "C:\Users\a\Desktop\SpeakEasyReports"
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/SpeakEasyReports.git
git push -u origin main
```

Sign in when GitHub asks.

---

## Step 2 — Connect repo in Codemagic (2 min)

1. Open https://codemagic.io/apps
2. Click **Add application**
3. Choose **GitHub** → authorize if asked
4. Select **SpeakEasyReports**
5. Codemagic finds **`codemagic.yaml`** → workflow **speakeasy-ios**

If asked for **Project path**, set: **`mobile`**

---

## Step 3 — Apple code signing (use your existing API key)

You already have an App Store Connect API key (`.p8`). Use it in Codemagic — no Apple ID password sign-in.

### 3a — Add the API key to Codemagic (skip if already connected)

1. Codemagic → click your **avatar** (bottom-left) → **Personal account settings** / **Team settings**
2. **Team integrations** → **Developer Portal** → **Manage keys** (or **Connect**)
3. **Add key** (or pick your existing key if it is already listed)
4. Enter:
   - **Key name** — any label, e.g. `SpeakEasy`
   - **Issuer ID** — from App Store Connect → Users and Access → Integrations → API
   - **Key ID** — from the same page
   - **`.p8` file** — your existing downloaded key (only needed once if not already uploaded)
5. Click **Save**

### 3b — Create signing files for SpeakEasy

Still in **Team settings** → **codemagic.yaml settings** → **Code signing identities**:

1. **iOS certificates** tab → **Generate certificate**
   - Reference name: `speakeasy-dist`
   - Type: **Apple Distribution** (needed for Ad Hoc / Diawi install — same as Expo preview builds)
   - API key: your new integrated key
   - **Create certificate** → if prompted, download once and **upload** it back
2. Create SpeakEasy on Apple Developer (required before a profile appears):
   - [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → **+** → App ID → `com.speakeasy.speakeasyReports`
   - [Profiles](https://developer.apple.com/account/resources/profiles/list) → **+** → **Ad Hoc** → pick `com.speakeasy.speakeasyReports` → your Distribution cert → your iPhone (already registered from Expo)
3. **iOS provisioning profiles** tab → **Fetch profiles**
   - Under **Ad Hoc profiles**, select **`com.speakeasy.speakeasyReports`** (ignore `com.varm.assessment` / `com.varm.ultimauhr` — those are old apps)
   - Reference name: `speakeasy-adhoc-profile` → **Download selected**

Green checkmark under **Certificate** on the profile = ready.

`codemagic.yaml` requests `distribution_type: ad_hoc` and bundle ID `com.speakeasy.speakeasyReports`.

---

## Step 4 — Start the build

1. Open your **SpeakEasyReports** app in Codemagic
2. Select workflow **SpeakEasy Reports iOS** (from codemagic.yaml)
3. Branch: **main**
4. Click **Start new build**
5. Wait ~15–25 min (first build downloads pods)

---

## Step 5 — Install on iPhone

1. When build is green, open the build → **Artifacts**
2. Download **`.ipa`**
3. Install options:
   - **TestFlight** (if you have Apple Developer)
   - **Diawi.com** — upload IPA, open link on iPhone (quick test)
   - iPhone: **Settings → General → VPN & Device Management** → Trust

---

## Step 6 — Connect to PC

1. PC: **SpeakEasy-Link.bat**
2. App **Settings** → `http://YOUR-PC-IP:3001`
3. **Test PC connection**

---

## If build fails

| Error | Fix |
|-------|-----|
| Code signing | Step 3 — API key in Developer Portal + cert/profile in Code signing identities |
| No matching profiles | Create bundle ID `com.speakeasy.speakeasyReports` in Apple Developer, then Fetch profiles again |
| Pod install | Re-run build (often fixes itself) |
| Wrong project | Set project path to `mobile` |
| Bundle ID mismatch | Keep `com.speakeasy.speakeasyReports` |

Paste the Codemagic error log in chat if stuck.