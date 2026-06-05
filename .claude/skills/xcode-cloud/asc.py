#!/usr/bin/env python3
"""Minimal App Store Connect API client — read/drive Xcode Cloud headlessly.

Auth (all via env; never hardcode or commit secrets):
  ASC_ISSUER    Issuer ID (UUID) — App Store Connect ▸ Users and Access ▸ Integrations.
  ASC_KEY_ID    Key ID — e.g. the XXXX in AuthKey_XXXX.p8.
  ASC_KEY_PATH  Path to the .p8 private key (default: ~/Downloads/AuthKey_${ASC_KEY_ID}.p8).

Usage:
  ASC_ISSUER=... ASC_KEY_ID=... python3 asc.py GET  <path-after-/v1/>
  ASC_ISSUER=... ASC_KEY_ID=... python3 asc.py POST <path> <body.json>

Recipes (Xcode Cloud) — see SKILL.md:
  GET  ciProducts                                  # find the product id
  GET  ciProducts/<id>/workflows                   # find the workflow id
  POST ciBuildRuns <body.json>                     # trigger a build (body in SKILL.md)
  GET  ciBuildRuns/<runId>                         # executionProgress / completionStatus
  GET  ciBuildRuns/<runId>/actions                 # per-action status (Build/Archive/...)
  GET  ciBuildActions/<actionId>/issues            # the human-readable failure messages
"""
import os, sys, time, json, urllib.request, urllib.error
import jwt  # PyJWT (pip install pyjwt cryptography)

def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("GET", "POST"):
        print(__doc__); sys.exit(2)
    method, path = sys.argv[1], sys.argv[2]

    issuer = os.environ["ASC_ISSUER"]
    key_id = os.environ["ASC_KEY_ID"]
    key_path = os.path.expanduser(
        os.environ.get("ASC_KEY_PATH", f"~/Downloads/AuthKey_{key_id}.p8"))
    with open(key_path) as f:
        private_key = f.read()

    token = jwt.encode(
        {"iss": issuer, "iat": int(time.time()), "exp": int(time.time()) + 900,
         "aud": "appstoreconnect-v1"},
        private_key, algorithm="ES256", headers={"kid": key_id, "typ": "JWT"})

    url = path if path.startswith("http") else f"https://api.appstoreconnect.apple.com/v1/{path}"
    headers = {"Authorization": f"Bearer {token}"}
    data = None
    if method == "POST":
        if len(sys.argv) < 4:
            print("POST needs a body.json path", file=sys.stderr); sys.exit(2)
        with open(sys.argv[3], "rb") as bf:
            data = bf.read()
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, headers=headers, data=data, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            body = r.read()
            print(json.dumps(json.loads(body), indent=2) if body else f"OK {r.status}")
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
