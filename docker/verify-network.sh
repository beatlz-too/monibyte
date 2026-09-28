#!/usr/bin/env bash
# Step 1 check: run containers reach model APIs through the proxy and nothing else.
set -uo pipefail
cd "$(dirname "$0")"

docker compose up -d --build --wait proxy >/dev/null || exit 1
fail=0

probe() { # image, expectation (allow|deny), url, extra docker args...
  local image=$1 expect=$2 url=$3; shift 3
  local code
  code=$(docker run --rm --network monibyte-sealed "$@" "$image" \
    curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$url")
  local got=deny; [[ $code =~ ^[1-5][0-9][0-9]$ && $code != 000 ]] && got=allow
  local mark=PASS; [[ $got == "$expect" ]] || { mark=FAIL; fail=1; }
  printf '%s  %-12s %-5s %-38s (http %s)\n' "$mark" "${image#monibyte/}" "$expect" "$url ${*:+[$*]}" "$code"
}

for cli in claude-code codex; do
  docker build -q -t "monibyte/$cli" "$cli" >/dev/null || exit 1
  via=(-e HTTPS_PROXY=http://proxy:8888 -e HTTP_PROXY=http://proxy:8888)
  probe "monibyte/$cli" allow https://api.anthropic.com "${via[@]}"
  probe "monibyte/$cli" allow https://api.openai.com "${via[@]}"
  probe "monibyte/$cli" deny  https://example.com "${via[@]}"
  probe "monibyte/$cli" deny  https://github.com "${via[@]}"
  probe "monibyte/$cli" deny  https://api.anthropic.com   # bypassing the proxy
  probe "monibyte/$cli" deny  https://1.1.1.1             # raw IP, no proxy
done

[[ $fail == 0 ]] && echo "OK: sealed network verified" || echo "FAILED"
exit $fail
