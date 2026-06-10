# Fix: No matching profiles for com.speakeasy.speakeasyReports

## TestFlight build (current workflow)

`codemagic.yaml` needs an **App Store** profile — not Development or Ad Hoc.

Run **`SETUP-Codemagic-Signing.bat`** — it opens the right pages.

### A. Codemagic — Apple Distribution certificate

Team settings → **Code signing identities** → **iOS certificates** → **Generate certificate**

| Field | Value |
|-------|-------|
| Type | **Apple Distribution** |
| Reference | `speakeasy-dist` |
| API key | your integrated SpeakEasy key |

If you already have 3 Distribution certs on Apple, **Fetch certificate** instead of Generate.

### B. Apple — App ID (if missing)

https://developer.apple.com/account/resources/identifiers/list → **+** → App IDs → `com.speakeasy.speakeasyReports`

### C. Apple — App Store profile

https://developer.apple.com/account/resources/profiles/add

1. **App Store** (under Distribution) → Continue
2. App ID: **`com.speakeasy.speakeasyReports`**
3. Certificate: **Apple Distribution** (from step A)
4. Name: `SpeakEasy App Store` → **Generate**

No device checkbox needed for App Store profiles.

### D. Codemagic — fetch App Store profile

**Code signing identities** → **iOS provisioning profiles** → **Fetch profiles**

1. Open **App Store profiles** (not Development, not Ad Hoc)
2. Tick **`com.speakeasy.speakeasyReports`**
3. Reference name: **`speakeasy-appstore-profile`**
4. **Download selected**
5. Confirm **green checkmark** under Certificate

### E. App Store Connect — app record (first time only)

https://appstoreconnect.apple.com → **Apps** → **+** → New App

- Bundle ID: `com.speakeasy.speakeasyReports`
- Name: SpeakEasy Reports (or your choice)

### F. Rebuild

SpeakEasyReports → **SpeakEasy Reports iOS** → **main** → **Start new build**

---

## Old Development / Diawi path (not used for TestFlight)

If you only have `speakeasy-dev-profile` (Development), that will **not** work with the current TestFlight workflow. You need step D above.

---

## Common errors

| Error | Fix |
|-------|-----|
| No matching profiles for `app_store` | Do step D — fetch **App Store** profile as `speakeasy-appstore-profile` |
| No matching profiles for `speakeasy-appstore-profile` | Reference name must match exactly in Codemagic |
| Certificate grey / no checkmark | Generate or fetch `speakeasy-dist` Distribution cert first |
| 3 Distribution certs limit | Revoke an old one in Apple Developer Portal, or fetch existing cert |
| App not found in App Store Connect | Do step E before first upload |