# Run the AnkiConnect query and count returned card ids.
fetch_anki() {
  # note, this ignores the deck limits, so is not really accurate until i start actually enabling all my decks.
  curl -sS localhost:8765 -X POST \
    -d '{"action": "findCards", "version": 5, "params": {"query": "is:due"}}' \
    | jq '.result | length'
}
anki_count=$(fetch_anki)
if [ -z "$anki_count" ] || [ "$anki_count" = "null" ]; then
  anki_indicator="☆ ?"
else
  anki_indicator="☆ ${anki_count}"
fi


# Extract Bunpro frontend_api_token from Microsoft Edge cookies (bunpro.jp) and read total_count.
get_bunpro_token() {
  python - <<'PY'
import sys

try:
  import browser_cookie3
except ImportError as exc:
  sys.stderr.write(f"missing browser_cookie3: {exc}\n")
  sys.exit(1)

COOKIE_NAME = "frontend_api_token"
DOMAIN = "bunpro.jp"

try:
  cookies = browser_cookie3.edge(domain_name=DOMAIN)
except Exception as exc:  # pragma: no cover - environment dependent
  sys.stderr.write(f"failed to read Edge cookies: {exc}\n")
  sys.exit(1)

for cookie in cookies:
  if cookie.name == COOKIE_NAME and DOMAIN in cookie.domain:
    print(cookie.value)
    sys.exit(0)

sys.exit(1)
PY
}

fetch_bunpro() {
  local token
  token=$(get_bunpro_token) || return 1
  if [ -z "$token" ]; then
    return 1
  fi
  curl -sS --location 'https://api.bunpro.jp/api/frontend/reviews' \
    --header "Authorization: Token token=${token}" \
    | jq '.total_count'
}

bunpro_count=$(fetch_bunpro)
if [ -z "$bunpro_count" ] || [ "$bunpro_count" = "null" ]; then
  bunpro_indicator="文 ?"
else
  bunpro_indicator="文 ${bunpro_count}"
fi

echo "${bunpro_indicator} ${anki_indicator}"