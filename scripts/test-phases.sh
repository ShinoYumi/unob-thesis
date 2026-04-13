#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
ROOT="${ROOT:-$(cd -- "$SCRIPT_DIR/.." && pwd -P)}"
TT="${TT:-$ROOT/.tools/tt}"
FONT_PATH="${FONT_PATH:-$ROOT/resources/fonts}"
if [[ -n "${TT_FONT_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  TT_FONT_ARGS_ARR=($TT_FONT_ARGS)
else
  TT_FONT_ARGS_ARR=(--font-path "$FONT_PATH" --use-system-fonts)
fi

if [[ ! -x "$TT" ]]; then
  echo "ERROR: tytanic binary not found: $TT"
  echo "Hint: set TT=/path/to/tt or download v0.3.3 binary"
  exit 2
fi

phase() {
  echo
  echo "== $1 =="
}

list_ids_no_skip() {
  local expr="$1"
  "$TT" list --root "$ROOT" "${TT_FONT_ARGS_ARR[@]}" --no-skip -e "$expr" 2>&1 \
    | awk 'NF {print $1}' \
    | rg '^(@template|[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+)$'
}

list_ids_skip_default() {
  local expr="$1"
  "$TT" list --root "$ROOT" "${TT_FONT_ARGS_ARR[@]}" -e "$expr" 2>&1 \
    | awk 'NF {print $1}' \
    | rg '^(@template|[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+)$'
}

count_lines() {
  local expr="$1"
  local mode="${2:-no-skip}"
  if [[ "$mode" == "skip-default" ]]; then
    list_ids_skip_default "$expr" | sed '/^$/d' | wc -l | tr -d ' '
  else
    list_ids_no_skip "$expr" | sed '/^$/d' | wc -l | tr -d ' '
  fi
}

expect_positive_count() {
  local expr="$1"
  local mode="${2:-no-skip}"
  local got
  got="$(count_lines "$expr" "$mode")"
  if [[ "$got" -lt 1 ]]; then
    echo "FAIL: expression '$expr' expected at least 1 test, got $got"
    echo "Resolved set:"
    if [[ "$mode" == "skip-default" ]]; then
      list_ids_skip_default "$expr" || true
    else
      list_ids_no_skip "$expr" || true
    fi
    exit 1
  fi
  echo "OK: '$expr' -> $got (>= 1)"
}

expect_equal_numbers() {
  local label="$1"
  local left="$2"
  local right="$3"
  if [[ "$left" != "$right" ]]; then
    echo "FAIL: $label expected equal values, got left=$left right=$right"
    exit 1
  fi
  echo "OK: $label -> $left == $right"
}

expect_contains() {
  local expr="$1"
  local id="$2"
  if ! list_ids_no_skip "$expr" | rg -Fxq "$id"; then
    echo "FAIL: expression '$expr' does not contain '$id'"
    echo "Resolved set:"
    list_ids_no_skip "$expr" || true
    exit 1
  fi
  echo "OK: '$expr' contains '$id'"
}

phase "1) Test-set grammar and discovery"
all_no_skip="$(count_lines 'all()')"
all_skip_default="$(count_lines 'all()' 'skip-default')"
skip_no_skip="$(count_lines 'skip()')"

expect_equal_numbers \
  "all() == all(skip-default) + skip()" \
  "$all_no_skip" \
  "$((all_skip_default + skip_no_skip))"
expect_positive_count 'compile-only() | ephemeral()'
expect_positive_count 'compile-only() & skip()'
expect_positive_count 'r:^phase/ & !skip()'
expect_positive_count '(r:^phase/ ~ skip()) | template()'

xor_left="$(count_lines 'compile-only() ^ skip()')"
xor_right="$(count_lines '(compile-only() ~ skip()) | (skip() ~ compile-only())')"
expect_equal_numbers "xor identity" "$xor_left" "$xor_right"

expect_contains 'compile-only() & skip()' 'phase/skip-sample'
expect_contains 'template()' '@template'

phase "2) Compile-only phase"
"$TT" run --root "$ROOT" "${TT_FONT_ARGS_ARR[@]}" --no-skip --no-fail-fast -e 'compile-only() & r:^phase/'

phase "3) Ephemeral phase"
"$TT" run --root "$ROOT" "${TT_FONT_ARGS_ARR[@]}" --no-skip --no-fail-fast -e 'ephemeral() & r:^phase/'

phase "4) Persistent phase"
"$TT" run --root "$ROOT" "${TT_FONT_ARGS_ARR[@]}" --no-skip --no-fail-fast -e 'persistent() & r:^phase/'

phase "5) Full phase suite"
"$TT" run --root "$ROOT" "${TT_FONT_ARGS_ARR[@]}" --no-fail-fast -e 'r:^phase/ ~ skip()'

echo
echo "All phases passed."
