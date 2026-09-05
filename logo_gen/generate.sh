#!/bin/bash
#
# generate.sh — (re)generate this theme's logo assets from the Omarchy wordmark.
#
# Usage:
#   ./generate.sh [target] [options]   (default target: all)
#
# Targets:
#   logo     Recolor SOURCE_SVG with LOGO_COLOR and render logo_gen/logo.png
#            (transparent working file, not part of the theme itself)
#   unlock   Copy logo_gen/logo.png -> ../unlock.png (theme root)
#   preview  Render ../preview-unlock.png via `omarchy plymouth preview`
#            (opens the result in imv for review)
#   all      logo + unlock + preview
#
# Options (each overrides the env var / default of the same name):
#   -s, --source-svg PATH    Wordmark SVG
#   -c, --logo-color HEX     Logo foreground color
#   -w, --logo-width PX      Logo width in px
#   -b, --bg-color HEX       Preview/boot background
#   -t, --text-color HEX     Preview/boot foreground
#   -h, --help               Show help
#
# Config defaults (used when neither flag nor env var is given):
#   SOURCE_SVG   ~/.local/share/omarchy/logo.svg
#   LOGO_COLOR   #98971a
#   LOGO_WIDTH   800
#   BG_COLOR     `background` from ../colors.toml
#   TEXT_COLOR   `foreground` from ../colors.toml
#
# Examples:
#   ./generate.sh all
#   ./generate.sh logo --logo-color '#d65d0e'
#   ./generate.sh preview -b '#1d2021' -t '#ebdbb2'
#   LOGO_COLOR='#d65d0e' ./generate.sh all   (env vars still work as defaults)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(dirname "$SCRIPT_DIR")"
COLORS_TOML="$THEME_DIR/colors.toml"

SOURCE_SVG="${SOURCE_SVG:-$HOME/.local/share/omarchy/logo.svg}"
LOGO_COLOR="${LOGO_COLOR:-#98971a}"
LOGO_WIDTH="${LOGO_WIDTH:-800}"

toml_value() { # $1 = key -> first non-commented #RRGGBB value
  grep -E "^$1[[:space:]]*=" "$COLORS_TOML" | head -n1 | grep -oE '#[0-9a-fA-F]{6}' | head -n1
}

BG_COLOR="${BG_COLOR:-$(toml_value background)}"
TEXT_COLOR="${TEXT_COLOR:-$(toml_value foreground)}"

WORK_LOGO="$SCRIPT_DIR/logo.png"
UNLOCK_PNG="$THEME_DIR/unlock.png"
PREVIEW_PNG="$THEME_DIR/preview-unlock.png"

die() { echo "error: $*" >&2; exit 1; }
valid_hex() { [[ "$1" =~ ^#[0-9a-fA-F]{6}$ ]]; }

usage() {
  cat <<EOF
Usage: generate.sh [target] [options]  (default target: all)

Targets:
  logo     Recolor the wordmark and render logo_gen/logo.png
  unlock   Copy logo_gen/logo.png -> ../unlock.png
  preview  Render ../preview-unlock.png via \`omarchy plymouth preview\`
  all      logo + unlock + preview

Options (override env vars of the same name):
  -s, --source-svg PATH   Wordmark SVG
  -c, --logo-color HEX    Logo foreground color
  -w, --logo-width PX     Logo width in px
  -b, --bg-color HEX      Preview/boot background
  -t, --text-color HEX    Preview/boot foreground
  -h, --help              Show this help

Examples:
  ./generate.sh all
  ./generate.sh logo --logo-color '#d65d0e'
  ./generate.sh preview -b '#1d2021' -t '#ebdbb2'
EOF
}

# Flags may come before or after the target; env vars act as defaults.
target=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -s|--source-svg) [[ $# -ge 2 ]] || die "missing value for '$1'"; SOURCE_SVG="$2"; shift 2 ;;
    -c|--logo-color) [[ $# -ge 2 ]] || die "missing value for '$1'"; LOGO_COLOR="$2"; shift 2 ;;
    -w|--logo-width) [[ $# -ge 2 ]] || die "missing value for '$1'"; LOGO_WIDTH="$2"; shift 2 ;;
    -b|--bg-color) [[ $# -ge 2 ]] || die "missing value for '$1'"; BG_COLOR="$2"; shift 2 ;;
    -t|--text-color) [[ $# -ge 2 ]] || die "missing value for '$1'"; TEXT_COLOR="$2"; shift 2 ;;
    --source-svg=*|--logo-color=*|--logo-width=*|--bg-color=*|--text-color=*)
      opt="${1%%=*}"; val="${1#*=}"
      [[ -n "$val" ]] || die "missing value for '$opt'"
      case "$opt" in
        --source-svg) SOURCE_SVG="$val" ;;
        --logo-color) LOGO_COLOR="$val" ;;
        --logo-width) LOGO_WIDTH="$val" ;;
        --bg-color) BG_COLOR="$val" ;;
        --text-color) TEXT_COLOR="$val" ;;
      esac
      shift ;;
    -*) die "unknown option '$1' (see --help)" ;;
    *) [[ -z "$target" ]] || die "unexpected argument '$1' (see --help)"; target="$1"; shift ;;
  esac
done
target="${target:-all}"

make_logo() {
  valid_hex "$LOGO_COLOR" || die "LOGO_COLOR='$LOGO_COLOR' is not #RRGGBB"
  [[ "$LOGO_WIDTH" =~ ^[0-9]+$ ]] || die "LOGO_WIDTH='$LOGO_WIDTH' is not a pixel count"
  [[ -f "$SOURCE_SVG" ]] || die "SOURCE_SVG not found: $SOURCE_SVG"
  local recolored
  recolored="$(mktemp --suffix=.svg)"
  sed "s/#000/${LOGO_COLOR}/g" "$SOURCE_SVG" >"$recolored"
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$LOGO_WIDTH" "$recolored" -o "$WORK_LOGO"
  elif command -v magick >/dev/null 2>&1; then
    magick -background none "$recolored" -resize "${LOGO_WIDTH}x" "$WORK_LOGO"
  else
    rm -f "$recolored"
    die "need rsvg-convert or magick to render the SVG"
  fi
  rm -f "$recolored"
  echo "wrote $WORK_LOGO ($LOGO_COLOR @ ${LOGO_WIDTH}px)"
}

make_unlock() {
  [[ -f "$WORK_LOGO" ]] || make_logo
  cp "$WORK_LOGO" "$UNLOCK_PNG"
  echo "wrote $UNLOCK_PNG"
}

make_preview() {
  valid_hex "$BG_COLOR" || die "BG_COLOR='$BG_COLOR' is not #RRGGBB"
  valid_hex "$TEXT_COLOR" || die "TEXT_COLOR='$TEXT_COLOR' is not #RRGGBB"
  [[ -f "$UNLOCK_PNG" ]] || make_unlock
  command -v omarchy >/dev/null 2>&1 || die "omarchy CLI not found"
  omarchy plymouth preview "$BG_COLOR" "$TEXT_COLOR" "$UNLOCK_PNG" "$PREVIEW_PNG"
  echo "wrote $PREVIEW_PNG"
}

case "$target" in
  logo) make_logo ;;
  unlock) make_unlock ;;
  preview) make_preview ;;
  all) make_logo && make_unlock && make_preview ;;
  *) die "unknown target '$target' (use logo|unlock|preview|all)" ;;
esac
