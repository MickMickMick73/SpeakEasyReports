#!/usr/bin/env python3
"""Create iOS App Store distribution certificate + provisioning profile via App Store Connect API."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import jwt
import requests
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID

API_BASE = "https://api.appstoreconnect.apple.com/v1"
BUNDLE_ID = "com.speakeasy.speakeasyReports"
CERT_REF_NAME = "SpeakEasy Distribution"
PROFILE_NAME = "SpeakEasy App Store"


def make_token(key_id: str, issuer_id: str, p8_path: Path) -> str:
    private_key = p8_path.read_text(encoding="utf-8")
    headers = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    now = int(time.time())
    payload = {"iss": issuer_id, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def api_request(method: str, token: str, path: str, **kwargs) -> requests.Response:
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    response = requests.request(method, f"{API_BASE}{path}", headers=headers, timeout=60, **kwargs)
    return response


def find_bundle_id(token: str, identifier: str) -> str:
    for candidate in (identifier, identifier.lower()):
        response = api_request(
            "GET",
            token,
            f"/bundleIds?filter[identifier]={candidate}&limit=1",
        )
        if response.status_code != 200:
            raise RuntimeError(f"bundleIds lookup failed ({response.status_code}): {response.text}")
        data = response.json().get("data", [])
        if data:
            print(f"Found bundle ID resource: {candidate} -> {data[0]['id']}")
            return data[0]["id"]
    raise RuntimeError(f"Bundle ID not found in Apple Developer: {identifier}")


def list_distribution_certs(token: str) -> list[dict]:
    response = api_request(
        "GET",
        token,
        "/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=200",
    )
    if response.status_code != 200:
        raise RuntimeError(f"certificates list failed ({response.status_code}): {response.text}")
    return response.json().get("data", [])


def create_csr() -> tuple[str, rsa.RSAPrivateKey]:
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    subject = x509.Name(
        [
            x509.NameAttribute(NameOID.COUNTRY_NAME, "AU"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "SpeakEasy Reports"),
            x509.NameAttribute(NameOID.COMMON_NAME, CERT_REF_NAME),
        ]
    )
    csr = (
        x509.CertificateSigningRequestBuilder()
        .subject_name(subject)
        .sign(private_key, hashes.SHA256())
    )
    csr_pem = csr.public_bytes(serialization.Encoding.PEM).decode("utf-8")
    return csr_pem, private_key


def create_distribution_cert(token: str, csr_pem: str) -> dict:
    payload = {
        "data": {
            "type": "certificates",
            "attributes": {
                "certificateType": "IOS_DISTRIBUTION",
                "csrContent": csr_pem,
            },
        }
    }
    response = api_request("POST", token, "/certificates", data=json.dumps(payload))
    if response.status_code in (200, 201):
        return response.json()["data"]

    body = response.text
    if response.status_code == 409 and "maximum number" in body.lower():
        existing = list_distribution_certs(token)
        if not existing:
            raise RuntimeError("Distribution cert limit reached and no existing cert found.")
        cert = existing[0]
        print(f"Using existing distribution certificate: {cert['id']}")
        return cert
    raise RuntimeError(f"create certificate failed ({response.status_code}): {body}")


def save_p12(private_key: rsa.RSAPrivateKey | None, cert_b64: str | None, out_path: Path, password: str) -> None:
    if private_key is None or cert_b64 is None:
        print("Skipped .p12 export (no private key for existing certificate).")
        return
    from cryptography.hazmat.primitives.serialization.pkcs12 import serialize_key_and_certificates

    cert_der = x509.load_der_x509_certificate(__import__("base64").b64decode(cert_b64))
    p12 = serialize_key_and_certificates(
        name=b"SpeakEasy Distribution",
        key=private_key,
        cert=cert_der,
        cas=None,
        encryption_algorithm=serialization.BestAvailableEncryption(password.encode("utf-8")),
    )
    out_path.write_bytes(p12)
    print(f"Wrote {out_path}")


def create_app_store_profile(token: str, bundle_resource_id: str, cert_id: str) -> dict:
    payload = {
        "data": {
            "type": "profiles",
            "attributes": {
                "name": PROFILE_NAME,
                "profileType": "IOS_APP_STORE",
            },
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle_resource_id}},
                "certificates": {"data": [{"type": "certificates", "id": cert_id}]},
            },
        }
    }
    response = api_request("POST", token, "/profiles", data=json.dumps(payload))
    if response.status_code in (200, 201):
        return response.json()["data"]

    if response.status_code == 409:
        response = api_request(
            "GET",
            token,
            f"/profiles?filter[name]={PROFILE_NAME.replace(' ', '%20')}&limit=5",
        )
        if response.status_code == 200:
            for item in response.json().get("data", []):
                if item.get("attributes", {}).get("profileType") == "IOS_APP_STORE":
                    print(f"Using existing profile: {item['id']}")
                    return item
    raise RuntimeError(f"create profile failed ({response.status_code}): {response.text}")


def download_profile(token: str, profile_id: str, out_path: Path) -> None:
    response = api_request("GET", token, f"/profiles/{profile_id}")
    if response.status_code != 200:
        raise RuntimeError(f"fetch profile failed ({response.status_code}): {response.text}")
    content = response.json()["data"]["attributes"].get("profileContent")
    if not content:
        raise RuntimeError("Profile has no profileContent yet; retry in a minute.")
    out_path.write_bytes(__import__("base64").b64decode(content))
    print(f"Wrote {out_path}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--issuer-id", default="1b6b813f-c052-4f70-9d24-8edf5ffd39e4")
    parser.add_argument("--key-id", default="N8MBR475HA")
    parser.add_argument("--p8", default=r"C:\Users\a\Desktop\aapple api stuff\AuthKey_N8MBR475HA.p8")
    parser.add_argument("--out-dir", default=r"C:\Users\a\Desktop\aapple api stuff")
    parser.add_argument("--p12-password", default="lAwTDGc5")
    parser.add_argument("--force-new-cert", action="store_true")
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    p8_path = Path(args.p8)
    if not p8_path.exists():
        print(f"Missing API key: {p8_path}", file=sys.stderr)
        return 1

    token = make_token(args.key_id, args.issuer_id, p8_path)
    bundle_resource_id = find_bundle_id(token, BUNDLE_ID)

    private_key: rsa.RSAPrivateKey | None = None
    cert_b64: str | None = None
    if args.force_new_cert:
        csr_pem, private_key = create_csr()
        cert = create_distribution_cert(token, csr_pem)
        cert_id = cert["id"]
        cert_b64 = cert.get("attributes", {}).get("certificateContent")
        print(f"Created distribution certificate: {cert_id}")
    else:
        existing = list_distribution_certs(token)
        if existing:
            cert = existing[0]
            cert_id = cert["id"]
            cert_b64 = cert.get("attributes", {}).get("certificateContent")
            print(f"Reusing distribution certificate: {cert_id}")
        else:
            csr_pem, private_key = create_csr()
            cert = create_distribution_cert(token, csr_pem)
            cert_id = cert["id"]
            cert_b64 = cert.get("attributes", {}).get("certificateContent")
            print(f"Created distribution certificate: {cert_id}")

    if cert_b64:
        cer_path = out_dir / "SpeakEasy_Distribution.cer"
        cer_path.write_bytes(__import__("base64").b64decode(cert_b64))
        print(f"Wrote {cer_path}")

    p12_path = out_dir / "SpeakEasy_Distribution.p12"
    save_p12(private_key, cert_b64, p12_path, args.p12_password)

    # Replace any existing App Store profile for this bundle so the new cert is used.
    response = api_request(
        "GET",
        token,
        "/profiles?filter[profileType]=IOS_APP_STORE&limit=200",
    )
    if response.status_code == 200:
        for item in response.json().get("data", []):
            rel = item.get("relationships", {}).get("bundleId", {}).get("data", {})
            if rel.get("id") == bundle_resource_id:
                delete = api_request("DELETE", token, f"/profiles/{item['id']}")
                print(f"Deleted old App Store profile {item['id']} ({delete.status_code})")

    profile = create_app_store_profile(token, bundle_resource_id, cert_id)
    profile_id = profile["id"]
    print(f"App Store profile id: {profile_id}")

    profile_path = out_dir / "SpeakEasy_AppStore.mobileprovision"
    download_profile(token, profile_id, profile_path)

    manifest = {
        "bundleId": BUNDLE_ID,
        "certificateId": cert_id,
        "profileId": profile_id,
        "codemagicCertificateRef": "speakeasy-dist",
        "codemagicProfileRef": "speakeasy-appstore-profile",
        "p12Path": str(p12_path),
        "profilePath": str(profile_path),
        "p12Password": args.p12_password,
    }
    manifest_path = out_dir / "SpeakEasy_AppStore_signing.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote {manifest_path}")
    print("Upload SpeakEasy_Distribution.p12 and SpeakEasy_AppStore.mobileprovision to Codemagic Code signing identities.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())