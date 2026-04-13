#!/bin/sh
set -eu

# Script: scripts/get-fonts.sh
# What: Stáhne a rozbalí fonty TeX Gyre Termes, Termes Math a Cursor.
# Why: Jednotný, opakovatelný setup fontů pro lokální kompilaci.

OUT_DIR="${OUT_DIR:-resources/fonts}"
URL_TERMES="${URL_TERMES:-https://www.gust.org.pl/projects/e-foundry/tex-gyre/termes/qtm2.004otf.zip}"
URL_MATH="${URL_MATH:-https://www.gust.org.pl/projects/e-foundry/tg-math/download/texgyretermes-math-1543.zip}"
URL_CURSOR="${URL_CURSOR:-https://www.gust.org.pl/projects/e-foundry/tex-gyre/cursor/tg_cursor-otf-2_609-31_03_2026.zip}"

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 2
}

command -v curl >/dev/null 2>&1 || die "Nenalezen příkaz curl"
command -v unzip >/dev/null 2>&1 || die "Nenalezen příkaz unzip"

mkdir -p "$OUT_DIR"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/unob-fonts.XXXXXX")"
trap 'rm -rf "$tmp_root"' EXIT INT TERM

termes_zip="$tmp_root/termes.zip"
math_zip="$tmp_root/termes-math.zip"
cursor_zip="$tmp_root/cursor.zip"
termes_dir="$tmp_root/termes"
math_dir="$tmp_root/math"
cursor_dir="$tmp_root/cursor"

printf '%s\n' '-> Download TeX Gyre Termes'
curl -fL --retry 3 --connect-timeout 15 --max-time 180 -o "$termes_zip" "$URL_TERMES"

printf '%s\n' '-> Download TeX Gyre Termes Math'
curl -fL --retry 3 --connect-timeout 15 --max-time 180 -o "$math_zip" "$URL_MATH"

printf '%s\n' '-> Download TeX Gyre Cursor'
curl -fL --retry 3 --connect-timeout 15 --max-time 180 -o "$cursor_zip" "$URL_CURSOR"

mkdir -p "$termes_dir" "$math_dir" "$cursor_dir"
unzip -oq "$termes_zip" -d "$termes_dir"
unzip -oq "$math_zip" -d "$math_dir"
unzip -oq "$cursor_zip" -d "$cursor_dir"

copied=0
find "$termes_dir" "$math_dir" "$cursor_dir" -type f -iname '*.otf' | while IFS= read -r font_file; do
  cp -f "$font_file" "$OUT_DIR/"
  copied=$((copied + 1))
  printf '   + %s\n' "$(basename "$font_file")"
done

# V subshellu (pipe) se copied nepropaguje, proto ověření přes find.
installed_count="$(find "$OUT_DIR" -maxdepth 1 -type f -iname '*.otf' | wc -l | tr -d ' ')"
[ "$installed_count" -gt 0 ] || die "Nepodařilo se nainstalovat žádný .otf font do $OUT_DIR"

printf 'OK: Fonts prepared in %s (%s .otf files found).\n' "$OUT_DIR" "$installed_count"
