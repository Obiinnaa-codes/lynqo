#!/usr/bin/env bash
# Dev-only AT&T WiFi Manager capture helper. Run while connected to the MiFi.
# Output redacts session IDs, tokens, and cookie values.
# For login_form verification with getpass, use: python3 tool/att_wifi_login_verify.py
set -euo pipefail

BASE="${ATT_WIFI_BASE_URL:-http://attwifimanager}"
WORKDIR="${TMPDIR:-/tmp}/lynqo-att-capture"
mkdir -p "$WORKDIR"

redact_url() {
  python3 - "$1" <<'PY'
import sys, urllib.parse
url = sys.argv[1]
uri = urllib.parse.urlparse(url)
q = {
    k: ("[REDACTED]" if k.lower() in {"sessionid", "token"} else v)
    for k, v in urllib.parse.parse_qsl(uri.query, keep_blank_values=True)
}
print(urllib.parse.urlunparse(uri._replace(query=urllib.parse.urlencode(q))))
PY
}

echo "=== GET / (redirect chain) ==="
curl -sS -L -D "$WORKDIR/headers.txt" -o "$WORKDIR/body.html" --max-time 20 "$BASE/" || true
grep -E '^(HTTP/|Location:|Set-Cookie:|Content-Type:)' "$WORKDIR/headers.txt" | while read -r line; do
  case "$line" in
    *Set-Cookie:*)
      name="${line#*Set-Cookie: }"; name="${name%%=*}"
      echo "Set-Cookie: ${name}=[REDACTED]"
      ;;
    *Location:*)
      loc="${line#*Location: }"
      echo "Location: $(redact_url "$loc")"
      ;;
    *) echo "$line" ;;
  esac
done

echo "=== Login form markers ==="
grep -o 'id="login_form"[^>]*action="[^"]*"' "$WORKDIR/body.html" | head -1 || echo "login_form not found"
grep -o 'name="session.password"' "$WORKDIR/body.html" | head -1 || true

echo "=== Script sources (first 5) ==="
grep -oE '<script[^>]+src="[^"]+"' "$WORKDIR/body.html" | head -5

JAR="$WORKDIR/cookies.txt"
curl -sS -c "$JAR" -b "$JAR" -L -o /dev/null --max-time 20 "$BASE/" || true

echo "=== Probe read-only JSON paths (status only) ==="
for path in "/api/model.json?internalapi=1" "/error.json" "/success.json"; do
  code=$(curl -sS -b "$JAR" -o "$WORKDIR/probe.json" -w "%{http_code}" --max-time 15 "$BASE${path}" || echo "000")
  echo "$path -> HTTP $code"
done

echo "Done. Raw files in $WORKDIR (do not commit)."
