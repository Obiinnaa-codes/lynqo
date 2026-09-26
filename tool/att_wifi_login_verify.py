#!/usr/bin/env python3
"""Dev-only AT&T WiFi Manager login verification (standard login_form path).

Reads admin password via getpass only. Never prints secrets.
Cookie jar and raw bodies stay under TMPDIR/lynqo-att-verify/ (do not commit).
"""

from __future__ import annotations

import argparse
import getpass
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.cookiejar import CookieJar
from pathlib import Path

BASE = os.environ.get("ATT_WIFI_BASE_URL", "http://attwifimanager")
WORKDIR = Path(os.environ.get("TMPDIR", "/tmp")) / "lynqo-att-verify"

AUTH_PATH = "/Forms/config"
MODEL_PATH = "/api/model.json"
INTERNAL_API = "1"
SESSION_COOKIE = "sessionId"
SESSION_QUERY = "sessionId"

ERR_REDIRECT = "/error.json"
OK_REDIRECT = "/success.json"

SENSITIVE_QUERY_KEYS = frozenset({"sessionid", "token"})


def redact_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if not parsed.query:
        return url
    pairs = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
    redacted = [
        (k, "[REDACTED]" if k.lower() in SENSITIVE_QUERY_KEYS else v)
        for k, v in pairs
    ]
    new_query = urllib.parse.urlencode(redacted)
    return urllib.parse.urlunparse(parsed._replace(query=new_query))


def log(msg: str) -> None:
    print(msg, flush=True)


def extract_session_id(jar: CookieJar) -> str | None:
    for cookie in jar:
        if cookie.name == SESSION_COOKIE and cookie.value and cookie.value != "unknown":
            return cookie.value
    return None


def extract_user_role(body: str) -> str | None:
    match = re.search(r'"userRole"\s*:\s*"([^"]+)"', body)
    return match.group(1) if match else None


def extract_sec_token(body: str) -> str | None:
    match = re.search(r'"secToken"\s*:\s*"([^"]+)"', body)
    return match.group(1) if match else None


def parse_login_form_field_names(html: str) -> list[str]:
    match = re.search(
        r'<form[^>]*id="login_form"[^>]*>(.*?)</form>',
        html,
        re.IGNORECASE | re.DOTALL,
    )
    if not match:
        return []
    fragment = match.group(1)
    names: list[str] = []
    for name_match in re.finditer(
        r'<input[^>]+name=["\']([^"\']+)["\']',
        fragment,
        re.IGNORECASE,
    ):
        names.append(name_match.group(1))
    return names


def login_response_summary(body: str) -> dict[str, object]:
    trimmed = body.strip()
    if not trimmed.startswith("{"):
        return {"type": "non_json", "preview": "[REDACTED body]"}
    try:
        data = json.loads(trimmed)
    except json.JSONDecodeError:
        return {"type": "invalid_json"}
    summary: dict[str, object] = {"type": "json", "keys": list(data.keys())}
    if "success" in data:
        summary["success"] = bool(data["success"])
    if "errno" in data:
        summary["errno"] = data["errno"]
    if "errdetail" in data:
        summary["errdetail"] = data["errdetail"]
    return summary


class Client:
    def __init__(self) -> None:
        WORKDIR.mkdir(parents=True, exist_ok=True)
        self.jar = CookieJar()
        jar_path = WORKDIR / "cookies.txt"
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.jar),
        )
        self._jar_path = jar_path

    def get(self, path: str, query: dict[str, str] | None = None) -> tuple[int, str, str]:
        url = BASE + path
        if query:
            url += "?" + urllib.parse.urlencode(query)
        req = urllib.request.Request(url)
        with self.opener.open(req, timeout=30) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            return resp.status, resp.geturl(), body

    def post_form(
        self,
        path: str,
        fields: dict[str, str],
        query: dict[str, str],
    ) -> tuple[int, str, str]:
        url = BASE + path + "?" + urllib.parse.urlencode(query)
        body = urllib.parse.urlencode(fields).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=body,
            method="POST",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        with self.opener.open(req, timeout=30) as resp:
            text = resp.read().decode("utf-8", errors="replace")
            return resp.status, resp.geturl(), text


def bootstrap(client: Client) -> tuple[str, str]:
    log("=== Step 1: Bootstrap GET / ===")
    status, final_url, html = client.get("/")
    log(f"HTTP status: {status}")
    log(f"Final URL (redacted): {redact_url(final_url)}")
    log(f"Set-Cookie: {SESSION_COOKIE}=[REDACTED]")
    session_id = extract_session_id(client.jar)
    if not session_id:
        log("ERROR: Could not obtain sessionId from cookie jar.")
        sys.exit(1)
    field_names = parse_login_form_field_names(html)
    log(f"login_form field names: {field_names or ['token', 'err_redirect', 'ok_redirect', 'session.password']}")
    return session_id, html


def fetch_model(client: Client, session_id: str, label: str) -> tuple[str | None, str | None]:
    log(f"=== {label}: GET {MODEL_PATH} ===")
    status, final_url, body = client.get(
        MODEL_PATH,
        {
            "internalapi": INTERNAL_API,
            SESSION_QUERY: session_id,
        },
    )
    log(f"HTTP status: {status}")
    log(f"Request URL (redacted): {redact_url(final_url)}")
    role = extract_user_role(body)
    token = extract_sec_token(body)
    log(f"userRole: {role or 'unknown'}")
    log(f"secToken present: {'yes' if token else 'no'} (value [REDACTED])")
    return role, token


def post_login(
    client: Client,
    session_id: str,
    sec_token: str,
    password: str,
    label: str,
) -> dict[str, object]:
    log(f"=== {label}: POST {AUTH_PATH} ===")
    log(f"Query param names: {SESSION_QUERY}=[REDACTED]")
    log("Form field names: token, err_redirect, ok_redirect, session.password")
    log("Form field values: [REDACTED]")
    log("Content-Type: application/x-www-form-urlencoded")
    log("Cookie header: sessionId=[REDACTED]")
    fields = {
        "token": sec_token,
        "err_redirect": ERR_REDIRECT,
        "ok_redirect": OK_REDIRECT,
        "session.password": password,
    }
    status, _final_url, body = client.post_form(
        AUTH_PATH,
        fields,
        {SESSION_QUERY: session_id},
    )
    summary = login_response_summary(body)
    log(f"HTTP status: {status}")
    log(f"Response summary: {summary}")
    return summary


def prompt_admin_password() -> str:
    if not sys.stdin.isatty() and sys.platform == "darwin":
        from subprocess import run

        script = (
            'display dialog "Enter AT&T WiFi Manager admin password:" '
            'default answer "" with hidden answer with title "lynqo verify"'
        )
        proc = run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode == 0:
            for part in proc.stdout.strip().split(", "):
                if part.startswith("text returned:"):
                    return part.split(":", 1)[1]

    try:
        return getpass.getpass("Admin password: ")
    except (EOFError, OSError):
        return ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify AT&T WiFi Manager login_form flow.")
    parser.add_argument(
        "--failed-only",
        action="store_true",
        help="Run bootstrap, pre-auth model, and one wrong-password POST only.",
    )
    parser.add_argument(
        "--skip-failed",
        action="store_true",
        help="Skip deliberate wrong-password attempt before real login.",
    )
    args = parser.parse_args()

    log(f"Target: {BASE}")
    log(f"Work directory (local only): {WORKDIR}")
    client = Client()

    session_id, _html = bootstrap(client)
    pre_role, sec_token = fetch_model(client, session_id, "Step 2: Pre-auth model")

    if not sec_token:
        log("ERROR: secToken missing from model.json; cannot POST login_form.")
        return 1

    if not args.skip_failed:
        log("=== Step 3: Failed login (wrong password) ===")
        post_login(
            client,
            session_id,
            sec_token,
            "definitely-wrong-password-for-verification",
            "Failed login POST",
        )
        role_after_fail, sec_token_after_fail = fetch_model(
            client,
            session_id,
            "After failed login: model.json",
        )
        log(f"userRole after failed login: {role_after_fail or 'unknown'}")
        if sec_token_after_fail:
            sec_token = sec_token_after_fail

    if args.failed_only:
        log("=== Done (--failed-only) ===")
        return 0

    log("=== Step 4: Real login (password not echoed) ===")
    real_password = prompt_admin_password()
    if not real_password:
        log(
            "ERROR: No password provided. Run from a terminal or approve the "
            "macOS password dialog.",
        )
        return 1

    _, sec_token = fetch_model(client, session_id, "Before real login: refresh model")
    if not sec_token:
        log("ERROR: secToken missing before real login POST.")
        return 1

    summary = post_login(
        client,
        session_id,
        sec_token,
        real_password,
        "Real login POST",
    )
    post_role, _ = fetch_model(client, session_id, "Step 5: Post-auth model")

    success_json = summary.get("type") == "json" and summary.get("success") is True
    verified = success_json and post_role == "Admin"

    log("=== Verification result ===")
    log(f"POST success JSON: {success_json}")
    log(f"Post-login userRole: {post_role or 'unknown'}")
    log(f"Pre-login userRole was: {pre_role or 'unknown'}")
    if verified:
        log("REAL LOGIN VERIFIED")
        return 0
    log("REAL LOGIN NOT VERIFIED")
    return 2


if __name__ == "__main__":
    sys.exit(main())
