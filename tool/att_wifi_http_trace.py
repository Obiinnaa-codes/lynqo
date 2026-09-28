#!/usr/bin/env python3
"""Trace AT&T WiFi Manager HTTP redirect chains (names only, no secret values)."""

from __future__ import annotations

import http.cookiejar
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = os.environ.get("ATT_WIFI_BASE_URL", "http://attwifimanager")
SENSITIVE_QUERY = frozenset({"sessionid", "token"})


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def redact_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if not parsed.query:
        return parsed.path or "/"
    pairs = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
    out: list[tuple[str, str]] = []
    for key, value in pairs:
        if key.lower() in SENSITIVE_QUERY:
            out.append((key, "[REDACTED]"))
        elif key == "oq":
            inner = urllib.parse.parse_qsl(value, keep_blank_values=True)
            inner = [
                (k, "[REDACTED]" if k.lower() in SENSITIVE_QUERY else v)
                for k, v in inner
            ]
            out.append((key, urllib.parse.urlencode(inner)))
        else:
            out.append((key, value))
    query = urllib.parse.urlencode(out)
    return f"{parsed.path or '/'}?{query}" if query else (parsed.path or "/")


def set_cookie_names(headers) -> list[str]:
    names: list[str] = []
    for raw in headers.get_all("Set-Cookie") or []:
        name = raw.split("=", 1)[0].strip()
        if name:
            names.append(name)
    return names


def jar_cookie_names(jar: http.cookiejar.CookieJar) -> list[str]:
    return sorted({c.name for c in jar})


def trace_get(
    jar: http.cookiejar.CookieJar,
    path: str,
    query: dict[str, str] | None = None,
    label: str = "GET",
    max_hops: int = 12,
) -> None:
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(jar),
        NoRedirect(),
    )
    url = BASE + path
    if query:
        url += "?" + urllib.parse.urlencode(query)

    print(f"\n=== {label} ===")
    for hop in range(1, max_hops + 1):
        req = urllib.request.Request(url)
        try:
            with opener.open(req, timeout=20) as resp:
                status = resp.status
                headers = resp.headers
                body = resp.read(400)
        except urllib.error.HTTPError as err:
            status = err.code
            headers = err.headers
            body = err.read(400)

        loc = headers.get("Location")
        print(f"hop{hop}: HTTP {status} {redact_url(url)}")
        if loc:
            print(f"  Location: {redact_url(urllib.parse.urljoin(url, loc))}")
        sc = set_cookie_names(headers)
        if sc:
            print(f"  Set-Cookie names: {', '.join(sc)}")
        print(f"  Cookie jar names: {', '.join(jar_cookie_names(jar)) or '(none)'}")
        ct = headers.get("Content-Type")
        if ct:
            print(f"  Content-Type: {ct.split(';')[0].strip()}")

        if status not in (301, 302, 303, 307, 308) or not loc:
            preview = body[:120].decode("utf-8", errors="replace").replace("\n", " ")
            if preview.strip().startswith("{") or preview.strip().startswith("["):
                keys = re.findall(r'"([A-Za-z_][A-Za-z0-9_]*)"\s*:', preview)
                if keys:
                    print(f"  JSON top-level keys (partial): {', '.join(keys[:12])}")
            elif "<html" in preview.lower():
                print("  Body: HTML")
            elif preview.strip():
                print("  Body: text (redacted preview omitted)")
            return

        url = urllib.parse.urljoin(url, loc)

    print("  (max hops reached)")


def main() -> int:
    jar = http.cookiejar.CookieJar()
    trace_get(jar, "/", label="Bootstrap GET /")
    trace_get(
        jar,
        "/api/model.json",
        {"internalapi": "1"},
        label="Pre-auth GET /api/model.json?internalapi=1 (no sessionId query)",
    )
    sid_present = any(c.name == "sessionId" for c in jar)
    print(f"\nCookie jar contains sessionId name: {'yes' if sid_present else 'no'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
