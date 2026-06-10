import base64
import json
import time
from pathlib import Path

import jwt
import requests

KEY_ID = "N8MBR475HA"
ISSUER = "1b6b813f-c052-4f70-9d24-8edf5ffd39e4"
P8 = Path(r"C:\Users\a\Desktop\aapple api stuff\AuthKey_N8MBR475HA.p8")
OUT = Path(r"C:\Users\a\Desktop\aapple api stuff")
CERT_ID = "LYT464LCGS"
BUNDLE_RES = "MMS8YPX3DZ"


def token() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        P8.read_text(encoding="utf-8"),
        algorithm="ES256",
        headers={"alg": "ES256", "kid": KEY_ID, "typ": "JWT"},
    )


def req(method: str, path: str, **kwargs) -> requests.Response:
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    return requests.request(
        method,
        f"https://api.appstoreconnect.apple.com/v1{path}",
        headers=headers,
        timeout=60,
        **kwargs,
    )


for profile_id in ("2LSCH8HPTJ",):
    deleted = req("DELETE", f"/profiles/{profile_id}")
    print(f"deleted {profile_id} -> {deleted.status_code}")

payload = {
    "data": {
        "type": "profiles",
        "attributes": {"name": "SpeakEasy App Store", "profileType": "IOS_APP_STORE"},
        "relationships": {
            "bundleId": {"data": {"type": "bundleIds", "id": BUNDLE_RES}},
            "certificates": {"data": [{"type": "certificates", "id": CERT_ID}]},
        },
    }
}
created = req("POST", "/profiles", data=json.dumps(payload))
print(f"create profile -> {created.status_code}")
profile_id = created.json()["data"]["id"]
fetched = req("GET", f"/profiles/{profile_id}")
content = fetched.json()["data"]["attributes"]["profileContent"]
(OUT / "SpeakEasy_AppStore.mobileprovision").write_bytes(base64.b64decode(content))
manifest = json.loads((OUT / "SpeakEasy_AppStore_signing.json").read_text(encoding="utf-8"))
manifest["certificateId"] = CERT_ID
manifest["profileId"] = profile_id
(OUT / "SpeakEasy_AppStore_signing.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print(f"profile {profile_id} saved")