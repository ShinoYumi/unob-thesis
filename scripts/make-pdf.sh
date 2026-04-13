#!/bin/sh
set -eu

# Script: scripts/make-pdf.sh
# What: Centralizuje build/watch/output logiku pro thesis PDF.
# Why: Udržuje Makefile krátký a lépe udržovatelný.

TYPST="${TYPST:-typst}"
ROOT="${ROOT:-.}"
SRC="${SRC:-template/thesis.typ}"
CFG="${CFG:-template/thesis.toml}"
OUT_DIR="${OUT_DIR:-build}"
TYPE="${TYPE:-auto}"
OPEN="${OPEN:-0}"
FONT_PATH="${FONT_PATH:-resources/fonts}"

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 2
}

check_inputs() {
  command -v "$TYPST" >/dev/null 2>&1 || {
    printf 'ERROR: typst není dostupný v PATH\n' >&2
    exit 127
  }
  [ -f "$SRC" ] || die "Chybí vstupní soubor $SRC"
  [ -f "$CFG" ] || die "Chybí konfigurační soubor $CFG"
  mkdir -p "$FONT_PATH"
}

extract_title() {
  awk '
    BEGIN { in_thesis = 0 }
    /^\[thesis\][[:space:]]*$/ { in_thesis = 1; next }
    /^\[[^]]+\][[:space:]]*$/ { if (in_thesis) exit; in_thesis = 0 }
    in_thesis && /^[[:space:]]*title[[:space:]]*=/ {
      line = $0
      sub(/^[[:space:]]*title[[:space:]]*=[[:space:]]*/, "", line)
      sub(/^"/, "", line)
      sub(/".*$/, "", line)
      print line
      exit
    }
  ' "$CFG"
}

extract_cfg_draft() {
  awk '
    BEGIN { in_root = 1 }
    /^[[:space:]]*\[[^]]+\][[:space:]]*$/ { in_root = 0 }
    in_root && /^[[:space:]]*draft[[:space:]]*=/ {
      line = $0
      sub(/^[[:space:]]*draft[[:space:]]*=[[:space:]]*/, "", line)
      sub(/[[:space:]]*#.*$/, "", line)
      sub(/[[:space:]]*$/, "", line)
      print line
      exit
    }
  ' "$CFG"
}

resolve_meta() {
  title="$(extract_title)"
  [ -n "$title" ] || die "V $CFG chybí [thesis].title"

  cfg_draft="$(extract_cfg_draft)"
  [ -n "$cfg_draft" ] || die "V $CFG chybí root hodnota draft = true|false"

  mode_lc="$(printf '%s' "$TYPE" | tr '[:upper:]' '[:lower:]')"
  case "$mode_lc" in
    auto|"")
      if [ "$cfg_draft" = "true" ]; then
        state="Draft"
        draft_value="true"
      elif [ "$cfg_draft" = "false" ]; then
        state="Final"
        draft_value="false"
      else
        die "Neplatná hodnota draft v $CFG, použij true nebo false"
      fi
      override_mode="false"
      ;;
    draft)
      state="Draft"
      draft_value="true"
      override_mode="true"
      ;;
    final)
      state="Final"
      draft_value="false"
      override_mode="true"
      ;;
    *)
      die "Neplatný TYPE='$TYPE'. Použij: auto | draft | final"
      ;;
  esac

  today="$(date +%F)"
  safe_title="$(printf '%s' "$title" | sed -E 's@[/:*?"<>|]@-@g; s/[[:space:]]+/ /g; s/^ +//; s/ +$//')"
  out="$OUT_DIR/$today - $safe_title - $state.pdf"
  latest="$OUT_DIR/latest-$(printf '%s' "$state" | tr '[:upper:]' '[:lower:]').pdf"
}

write_override_cfg() {
  target_cfg="$1"
  awk -v draft="$draft_value" '
    BEGIN { in_root = 1; done = 0 }
    {
      if (in_root && $0 ~ /^[[:space:]]*\[[^]]+\][[:space:]]*$/) {
        if (!done) { print "draft = " draft; done = 1 }
        in_root = 0
      }
      if (in_root && $0 ~ /^[[:space:]]*draft[[:space:]]*=/) {
        if (!done) { print "draft = " draft; done = 1 }
        next
      }
      print $0
    }
    END {
      if (!done) print "draft = " draft
    }
  ' "$CFG" > "$target_cfg"
}

write_override_typ() {
  target_typ="$1"
  cfg_rel="$2"
  awk -v cfg_path="$cfg_rel" '
    BEGIN { done = 0 }
    {
      if (!done && $0 ~ /^#show:[[:space:]]*thesis[[:space:]]*$/) {
        print "#show: thesis.with(file: \"" cfg_path "\")"
        done = 1
        next
      }
      print $0
    }
    END {
      if (!done) {
        print "ERROR: V " FILENAME " chybí radek #show: thesis" > "/dev/stderr"
        exit 2
      }
    }
  ' "$SRC" > "$target_typ"
}

open_output_if_requested() {
  if [ "$OPEN" != "1" ]; then
    return 0
  fi

  if command -v open >/dev/null 2>&1; then
    open "$out"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$out" >/dev/null 2>&1 || true
  else
    printf 'WARN: OPEN=1, ale nenalezeno `open` ani `xdg-open`.\n' >&2
  fi
}

compile_pdf() {
  check_inputs
  mkdir -p "$OUT_DIR"
  resolve_meta

  printf -- '-> %s\n' "$out"
  if [ "$override_mode" = "false" ]; then
    "$TYPST" compile --root "$ROOT" --font-path "$FONT_PATH" "$SRC" "$out"
  else
    tmp_cfg_name=".tmp-thesis-$PPID-$state.toml"
    tmp_typ_name=".tmp-thesis-$PPID-$state.typ"
    tmp_cfg="$OUT_DIR/$tmp_cfg_name"
    tmp_typ="$OUT_DIR/$tmp_typ_name"
    tmp_cfg_rel="../$OUT_DIR/$tmp_cfg_name"
    trap 'rm -f "$tmp_cfg" "$tmp_typ"' EXIT INT TERM

    write_override_cfg "$tmp_cfg"
    write_override_typ "$tmp_typ" "$tmp_cfg_rel"

    "$TYPST" compile --root "$ROOT" --font-path "$FONT_PATH" "$tmp_typ" "$out"
  fi

  ln -sfn "$(basename "$out")" "$latest"
  open_output_if_requested
}

watch_pdf() {
  check_inputs
  mkdir -p "$OUT_DIR"
  resolve_meta

  printf -- '-> %s\n' "$out"
  ln -sfn "$(basename "$out")" "$latest"
  if [ "$override_mode" = "false" ]; then
    "$TYPST" watch --root "$ROOT" --font-path "$FONT_PATH" "$SRC" "$out"
  else
    tmp_cfg_name=".tmp-thesis-watch-$PPID-$state.toml"
    tmp_typ_name=".tmp-thesis-watch-$PPID-$state.typ"
    tmp_cfg="$OUT_DIR/$tmp_cfg_name"
    tmp_typ="$OUT_DIR/$tmp_typ_name"
    tmp_cfg_rel="../$OUT_DIR/$tmp_cfg_name"
    trap 'rm -f "$tmp_cfg" "$tmp_typ"' EXIT INT TERM

    write_override_cfg "$tmp_cfg"
    write_override_typ "$tmp_typ" "$tmp_cfg_rel"

    "$TYPST" watch --root "$ROOT" --font-path "$FONT_PATH" "$tmp_typ" "$out"
  fi
}

output_path() {
  check_inputs
  mkdir -p "$OUT_DIR"
  resolve_meta
  printf '%s\n' "$out"
}

check_mode() {
  check_inputs
  printf 'OK: check passed (TYPST=%s, SRC=%s, CFG=%s, FONT_PATH=%s)\n' "$TYPST" "$SRC" "$CFG" "$FONT_PATH"
}

cmd="${1:-compile}"
case "$cmd" in
  check) check_mode ;;
  compile) compile_pdf ;;
  watch) watch_pdf ;;
  output) output_path ;;
  *)
    die "Neznámý příkaz '$cmd'. Použij: check | compile | watch | output"
    ;;
esac
