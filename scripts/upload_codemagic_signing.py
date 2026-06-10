#!/usr/bin/env python3
"""Upload SpeakEasy iOS signing secret to Codemagic via REST API."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import requests

API_V3 = "https://codemagic.io/api/v3"
BUILDS_API = "https://api.codemagic.io/builds"
DEFAULT_APP_ID = "6a27821beac151109029feea"
DEFAULT_GROUP = "code-signing"
DEFAULT_VAR = "CERTIFICATE_PRIVATE_KEY"
DEFAULT_PEM = Path.home() / "Desktop" / "aapple api stuff" / "SpeakEasy_distribution_private_key.pem"
DEFAULT_TOKEN_FILE = Path.home() / "Desktop" / "aapple api stuff" / "codemagic-api-token.txt"


def load_token(explicit: str | None, token_file: Path) -> str:
    if explicit:
        return explicit.strip()
    env = os.environ.get("CODEMAGIC_API_TOKEN", "").strip()
    if env:
        return env
    if token_file.is_file():
        token = token_file.read_text(encoding="utf-8").strip()
        if token:
            return token
    raise RuntimeError(
        "Codemagic API token missing. Set CODEMAGIC_API_TOKEN, pass --api-token, or save the token to "
        f"{token_file}"
    )


def request(
    method: str,
    token: str,
    url: str,
    *,
    payload: dict | None = None,
) -> requests.Response:
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "x-auth-token": token,
    }
    return requests.request(method, url, headers=headers, json=payload, timeout=60)


def list_variable_groups(token: str, app_id: str) -> list[dict]:
    response = request("GET", token, f"{API_V3}/apps/{app_id}/variable-groups")
    if response.status_code != 200:
        raise RuntimeError(f"List variable groups failed ({response.status_code}): {response.text}")
    return response.json().get("data", [])


def ensure_group(token: str, app_id: str, group_name: str) -> str:
    groups = list_variable_groups(token, app_id)
    for group in groups:
        if group.get("name") == group_name:
            return group["id"]

    response = request(
        "POST",
        token,
        f"{API_V3}/apps/{app_id}/variable-groups",
        payload={"name": group_name},
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Create variable group failed ({response.status_code}): {response.text}")
    body = response.json()
    group_id = body.get("id") or body.get("data", {}).get("id")
    if not group_id:
        groups = list_variable_groups(token, app_id)
        for group in groups:
            if group.get("name") == group_name:
                return group["id"]
        raise RuntimeError(f"Created group '{group_name}' but could not resolve id: {body}")
    return group_id


def list_variables(token: str, group_id: str) -> list[dict]:
    response = request("GET", token, f"{API_V3}/variable-groups/{group_id}/variables")
    if response.status_code != 200:
        raise RuntimeError(f"List variables failed ({response.status_code}): {response.text}")
    return response.json().get("data", [])


def upsert_secret(token: str, group_id: str, name: str, value: str) -> None:
    variables = list_variables(token, group_id)
    existing = next((item for item in variables if item.get("name") == name), None)
    if existing:
        response = request(
            "PATCH",
            token,
            f"{API_V3}/variable-groups/{group_id}/variables/{existing['id']}",
            payload={"name": name, "value": value, "secure": True},
        )
        if response.status_code not in (200, 204):
            raise RuntimeError(f"Update variable failed ({response.status_code}): {response.text}")
        print(f"Updated secret variable '{name}' in group {group_id}")
        return

    response = request(
        "POST",
        token,
        f"{API_V3}/variable-groups/{group_id}/variables",
        payload={"secure": True, "variables": [{"name": name, "value": value}]},
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Create variable failed ({response.status_code}): {response.text}")
    print(f"Created secret variable '{name}' in group {group_id}")


def trigger_build(token: str, app_id: str, workflow_id: str, branch: str) -> dict:
    headers = {
        "Content-Type": "application/json",
        "x-auth-token": token,
    }
    payload = {
        "appId": app_id,
        "workflowId": workflow_id,
        "branch": branch,
        "environment": {"groups": [DEFAULT_GROUP]},
    }
    response = requests.post(BUILDS_API, headers=headers, json=payload, timeout=60)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Trigger build failed ({response.status_code}): {response.text}")
    body = response.json()
    print(f"Triggered build on branch '{branch}' workflow '{workflow_id}'")
    if isinstance(body, dict):
        build = body.get("build") or body
        build_id = build.get("_id") or build.get("id")
        if build_id:
            print(f"Build URL: https://codemagic.io/app/{app_id}/build/{build_id}")
    return body


def main() -> int:
    parser = argparse.ArgumentParser(description="Upload CERTIFICATE_PRIVATE_KEY to Codemagic")
    parser.add_argument("--api-token", help="Codemagic personal API token")
    parser.add_argument("--token-file", type=Path, default=DEFAULT_TOKEN_FILE)
    parser.add_argument("--app-id", default=DEFAULT_APP_ID)
    parser.add_argument("--group", default=DEFAULT_GROUP)
    parser.add_argument("--pem", type=Path, default=DEFAULT_PEM)
    parser.add_argument("--trigger-build", action="store_true", help="Start speakeasy-ios on main after upload")
    parser.add_argument("--workflow-id", default="speakeasy-ios")
    parser.add_argument("--branch", default="main")
    args = parser.parse_args()

    if not args.pem.is_file():
        raise SystemExit(f"Private key not found: {args.pem}")

    pem_value = args.pem.read_text(encoding="utf-8").strip()
    if "BEGIN PRIVATE KEY" not in pem_value:
        raise SystemExit(f"File does not look like a PEM private key: {args.pem}")

    token = load_token(args.api_token, args.token_file)
    group_id = ensure_group(token, args.app_id, args.group)
    upsert_secret(token, group_id, DEFAULT_VAR, pem_value)

    print("Codemagic automatic signing upload complete.")
    print(f"App: {args.app_id}")
    print(f"Group: {args.group} ({group_id})")
    print(f"Variable: {DEFAULT_VAR}")

    if args.trigger_build:
        trigger_build(token, args.app_id, args.workflow_id, args.branch)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)