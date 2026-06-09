# Fix: No matching profiles for com.speakeasy.speakeasyReports

Codemagic needs a profile in **Code signing identities**. Use **Development** (easier than Ad Hoc).

Your iPhone is already registered: **UDID `00008150-001A58110CF1401C`**

Run **`SETUP-Codemagic-Signing.bat`**

## Order matters: Codemagic FIRST, then Apple

### A. Codemagic — certificate

Team settings → **Code signing identities** → **iOS certificates** → **Generate certificate**

| Field | Value |
|-------|-------|
| Type | **Apple Development** |
| Reference | `speakeasy-dev` |
| API key | your integrated key |

### B. Apple — App ID (if missing)

https://developer.apple.com/account/resources/identifiers/list → **+** → `com.speakeasy.speakeasyReports`

### C. Apple — Development profile (NOT Ad Hoc)

https://developer.apple.com/account/resources/profiles/add

1. **iOS App Development** → Continue
2. App ID: **`com.speakeasy.speakeasyReports`**
3. Certificate: **Apple Development** / **iPhone Developer** (from step A)
4. Devices: **tick the checkbox** next to your iPhone ← **Generate stays grey without this**
5. Name: `SpeakEasy Dev` → **Generate** → **Download** (optional)

### Stuck on Generate?

| Symptom | Fix |
|---------|-----|
| Generate greyed out | Tick **device checkbox** and **certificate** |
| No Distribution cert | Use **Development** profile instead (step C) |
| No devices listed | https://developer.apple.com/account/resources/devices/list — add iPhone UDID above |
| No App ID | Do step B first |

### D. Codemagic — fetch profile

**iOS provisioning profiles** → **Fetch profiles** → **Development profiles** → `com.speakeasy.speakeasyReports` → `speakeasy-dev-profile` → **Download selected**

### E. Rebuild

SpeakEasyReports → **SpeakEasy Reports iOS** → **main** → **Start new build**

## After install

1. **SpeakEasy-Link.bat** on PC
2. App Settings → `http://192.168.1.110:3001`