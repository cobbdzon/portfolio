#!/usr/bin/env bash
#
# Forces Meta (Facebook, Messenger, Instagram DMs, WhatsApp) to re-crawl the
# link preview.
#
# Meta caches parsed Open Graph data for ~30 days per URL, and that one cache
# is shared across every Meta surface. Until it is invalidated, a shared link
# keeps showing the old title, description and image — even after the page
# itself has been updated.
#
# The og:image URL carries a ?v=N cache-busting parameter, so bumping that
# number in index.html gives the crawler a new image to fetch. This script
# handles the other half: invalidating Meta's cached parse of the page.
#
# Usage:
#   tools/rescrape.sh                 # print the debugger link (no login needed)
#   tools/rescrape.sh <access_token>  # also call the Graph API directly
#
# Get an access token from any Meta App's dashboard -> Settings -> Basic ->
# "App secret" -> "Generate token" -> "app_access_token". An app access token
# is server-to-server, long-lived, and needs no review for the scrape call.
#
set -euo pipefail

URL="${SITE_URL:-https://cobbdzon.cc/}"
DEBUGGER="https://developers.facebook.com/tools/debug/"

printf '\033[36m==>\033[0m Meta rescrape for %s\n\n' "$URL"

if [ $# -ge 1 ] && [ -n "${1:-}" ]; then
  TOKEN="$1"
  printf '\033[36m==>\033[0m calling the Graph API scrape endpoint\n'
  curl -sS -X POST "https://graph.facebook.com/v19.0/" \
    -F "id=${URL}" \
    -F "scrape=true" \
    -F "access_token=${TOKEN}" \
    | head -c 4000
  printf '\n\n'
  printf 'Meta caches for ~30 days per URL and is rate limited to roughly one\n'
  printf 'scrape per 30s. If the response looks unchanged, wait a minute and retry.\n'
else
  printf 'No access token given, so here is the manual route:\n\n'
  printf '  1. Open  %s\n' "$DEBUGGER"
  printf '  2. Paste %s\n' "$URL"
  printf '  3. Click "Debug", then "Scrape Again"\n\n'
  printf '  If "Scrape Again" does nothing, submit this URL instead — Meta treats\n'
  printf '  the extra parameter as a different page and refetches fresh:\n\n'
  printf '      %s?fbrefresh=%s\n\n' "$URL" "$(date +%Y%m%d%H%M%S)"
  printf '  Preview cache is shared, so one successful scrape fixes Facebook,\n'
  printf '  Messenger, Instagram DMs and WhatsApp at the same time.\n'
  printf '  Note: previews already posted to a feed keep their old image.\n\n'
fi
