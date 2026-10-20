#!/usr/bin/env bash
#
# Regenerates the static image assets that the site links to from its <head>:
#
#   og.png              1200x630 Open Graph / Twitter card
#   favicon.ico         16/32/48 multi-size fallback
#   apple-touch-icon.png  180x180 iOS home-screen icon
#
# favicon.svg is edited directly at the repo root; the rest are derived from
# it and from tools/og-source.svg.
#
# Usage:  tools/render-assets.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/tools"

# The font is cached outside the repo so nothing binary lands in git.
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/portfolio-assets"
FONT_DIR="$CACHE/fonts"
FONT_TTF="$FONT_DIR/PlusJakartaSans.ttf"
FONT_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf"

die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[36m==>\033[0m %s\n' "$*"; }

command -v rsvg-convert >/dev/null || die "rsvg-convert not found (Debian/Ubuntu: apt install librsvg2-bin)"
command -v magick      >/dev/null || command -v convert >/dev/null || die "ImageMagick not found (apt install imagemagick)"

# ---------------------------------------------------------------------------
# Font: Plus Jakarta Sans (SIL Open Font License 1.1)
#
# The site loads this face from Google Fonts; the SVG renderer needs it
# installed locally. It is fetched once into the cache directory and exposed
# to fontconfig through a private config file, so the user's system fonts
# are left untouched.
# ---------------------------------------------------------------------------
if [ ! -s "$FONT_TTF" ]; then
  info "fetching Plus Jakarta Sans"
  mkdir -p "$FONT_DIR"
  curl -fsSL --retry 3 -o "$FONT_TTF.part" "$FONT_URL" \
    || die "could not download the font from $FONT_URL"
  mv "$FONT_TTF.part" "$FONT_TTF"
else
  info "using cached font"
fi

FONTCONFIG_FILE="$CACHE/fonts.conf"
mkdir -p "$CACHE"
cat > "$FONTCONFIG_FILE" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>$FONT_DIR</dir>
</fontconfig>
EOF
export FONTCONFIG_FILE

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
info "rendering og.png"
rsvg-convert -w 1200 -h 630 "$TOOLS/og-source.svg" -o "$ROOT/og.png"

info "rendering favicon.ico"
if command -v magick >/dev/null; then
  magick "$ROOT/favicon.svg" -define icon:auto-resize=64,48,32,16 "$ROOT/favicon.ico"
else
  convert "$ROOT/favicon.svg" -define icon:auto-resize=64,48,32,16 "$ROOT/favicon.ico"
fi

info "rendering apple-touch-icon.png"
rsvg-convert -w 180 -h 180 "$ROOT/favicon.svg" -o "$ROOT/apple-touch-icon.png"

info "done"
for f in og.png favicon.svg favicon.ico apple-touch-icon.png; do
  printf '    %-22s %s\n' "$f" "$(du -h "$ROOT/$f" | cut -f1)"
done
