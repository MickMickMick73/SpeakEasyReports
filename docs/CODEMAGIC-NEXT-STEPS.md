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

## Step 3 — Apple code signing (required)

1. Codemagic → **Teams** (or personal settings) → **Code signing identities**
2. **iOS** → **Add credentials**
3. Sign in with your **Apple ID** (the one used on your iPhone)
4. Bundle ID: **`com.speakeasy.speakeasyReports`**

Free Apple ID = development install (~7 days). Paid Developer ($99/yr) = TestFlight.

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
| Code signing | Step 3 — add Apple ID in Codemagic |
| Pod install | Re-run build (often fixes itself) |
| Wrong project | Set project path to `mobile` |
| Bundle ID mismatch | Keep `com.speakeasy.speakeasyReports` |

Paste the Codemagic error log in chat if stuck.