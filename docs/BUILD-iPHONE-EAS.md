# iPhone build — EAS (recommended, same as InspectPro)

Codemagic needs manual cert/profile clicking. **EAS handles Apple signing on Expo's servers** — the path you already used successfully.

## One command

Double-click **`BUILD-iPhone-EAS.bat`** in the SpeakEasyReports folder.

Or in PowerShell:

```powershell
cd "C:\Users\a\Desktop\SpeakEasyReports\mobile"
npx eas-cli build --platform ios --profile preview
```

Account: **mikeykool401** (already logged in on this PC).

Project: https://expo.dev/accounts/mikeykool401/projects/speakeasy-reports

## First build only (~2 min of prompts)

EAS may ask **once** for the new bundle ID `com.speakeasy.speakeasyReports`:

- Use **remote credentials** (Expo server) — same as InspectPro
- Distribution: **internal** (Ad Hoc install link)
- If asked to register iPhone: pick **Website** → open URL on phone in Safari

After that, future builds are mostly hands-off.

## Install

When build finishes, EAS shows a **QR code / install link**. Open on iPhone in Safari.

Then in the app: **Settings** → `http://YOUR-PC-IP:3001` (with **SpeakEasy-Link.bat** running).

## Credits

EAS uses build minutes from your Expo plan. If you hit the credit wall again, wait for reset or use Codemagic (`docs/CODEMAGIC-NEXT-STEPS.md`) as backup.