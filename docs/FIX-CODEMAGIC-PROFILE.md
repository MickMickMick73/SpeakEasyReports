# Fix: No matching profiles for com.speakeasy.speakeasyReports

Build **6a279b311de96379218e8897** failed because Codemagic has **no Ad Hoc profile** for SpeakEasy in **Code signing identities**.

EAS saying "credentials ready" only means **Expo's servers** — Codemagic does not see those files.

## Fix (one time, ~5 minutes)

Run **`SETUP-Codemagic-Signing.bat`** or follow below.

### 1. Apple — App ID

https://developer.apple.com/account/resources/identifiers/list

- If **`com.speakeasy.speakeasyReports`** is **not** in the list:
  - **+** → App IDs → App → Explicit → `com.speakeasy.speakeasyReports` → Register

### 2. Apple — Ad Hoc profile

https://developer.apple.com/account/resources/profiles/list

- **+** → **Ad Hoc** → Continue
- App ID: **`com.speakeasy.speakeasyReports`**
- Certificate: **Apple Distribution** (same team as InspectPro, H9PMCU8928)
- Devices: your **iPhone** (already registered from Expo)
- Name: `SpeakEasy AdHoc` → Generate

### 3. Codemagic — fetch into vault

https://codemagic.io/teams/6a277febc3867daed2847fcf → **Team settings** → **codemagic.yaml settings** → **Code signing identities**

**iOS certificates** (if empty): **Generate certificate** → Apple Distribution → `speakeasy-dist`

**iOS provisioning profiles** → **Fetch profiles** → under **Ad Hoc profiles** select **`com.speakeasy.speakeasyReports`** → reference `speakeasy-adhoc` → **Download selected**

Do **not** use `com.varm.assessment` or `com.varm.ultimauhr`.

Green checkmark under **Certificate** = good.

### 4. Rebuild

Codemagic → **SpeakEasyReports** → **SpeakEasy Reports iOS** → branch **main** → **Start new build**

## After install

1. **SpeakEasy-Link.bat** on PC
2. App Settings → `http://192.168.1.110:3001`