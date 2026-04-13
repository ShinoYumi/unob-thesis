# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A Typst thesis template for the University of Defence (Univerzita obrany, UNOB) in Brno, Czech Republic. Supports four faculties (`fvl`, `fvt`, `vlf`, `uo`), Czech/English bilingual output, draft/final modes, and TOML-based user configuration.

## Build Commands

```bash
make pdf              # Compile thesis to PDF
make watch            # Continuous compilation on file save
make get-fonts        # Download required TeX Gyre fonts to resources/fonts/
make check            # Verify tools and input files are available
make clean            # Remove .tmp-* files from build/
make distclean        # Remove entire build/ directory
```

**Key Makefile variables:**
- `TYPE=draft` or `TYPE=final` — override compilation mode
- `SRC=template/thesis.typ` — input file (default)
- `CFG=template/thesis.toml` — config file (default)
- `OPEN=1` — auto-open PDF after build

Output files: `build/YYYY-MM-DD - <Title> - Draft.pdf` with symlinks `build/latest-draft.pdf` / `build/latest-final.pdf`.

## Test Commands

Tests use [Tytanic](https://github.com/typst-community/tytanic) (`tt`):

```bash
make test                        # Run all five test phases
make update-refs                 # Rebuild persistent reference images after intentional visual changes
TT=/path/to/tt make test         # Use a custom tytanic binary
```

The five phases (defined in `scripts/test-phases.sh`):
1. **Grammar** — validates Tytanic test expression operators
2. **Compile-only** — tests that only check successful compilation
3. **Ephemeral** — visual regression against in-memory references
4. **Persistent** — visual regression against checked-in PNGs in `tests/phase/*/ref/`
5. **Full** — complete suite excluding `skip()`-marked tests

Tytanic config in `typst.toml`: 1px max-delta tolerance, 144 DPI.

CI (`tytanic-tests.yml`) uploads diff/out/ref PNGs as artifacts on failure (5-day retention).

## Architecture

### Entry Points

- **`src/lib.typ`** — Public API. Exports all user-facing functions and implements the `#show: thesis` rule that assembles the document. This is the `entrypoint` in `typst.toml`.
- **`template/thesis.typ`** — User's document. Applies `#show: thesis` then writes chapter content.
- **`template/thesis.toml`** — User configuration (metadata, faculty, draft mode, bibliography, which front/back matter pages to include).

### Module Map (`src/modules/`)

| Module | Role |
|---|---|
| `config.typ` | Loads and validates `thesis.toml`; all config access goes through here |
| `i18n.typ` | All Czech/English strings and faculty names |
| `styles.typ` | Base typography, heading styles, figure/table styles |
| `cover.typ` | Title page rendering (different layout per faculty) |
| `frontmatter.typ` | Assignment, declaration, abstracts; reads metadata set by helpers in `lib.typ` |
| `glossary.typ` | Acronym/term management with used-only filtering; wraps `vendor/glossarium` |
| `notes.typ` | Callout blocks (`#warning`, `#definition`, `#example`, etc.) |
| `lists.typ` | TOC and lists of figures/tables/equations/listings |
| `annex.typ` | Annex mode with re-numbered headings/figures |
| `drafting.typ` | Draft watermark and `#todo` annotations |
| `validation.typ` | Pre-submission checks when `submit_check = true` |
| `utils.typ` | Small shared helpers |

### Configuration Schema (`thesis.toml`)

```toml
lang = "cs"            # "cs" | "en"
draft = false          # enables watermark, #todo blocks
faculty = "fvl"        # "fvl" | "fvt" | "vlf" | "uo"

[author]
sex = "M"              # "M" | "F" — affects Czech grammar on declaration page

[lists]                # toggle each front/back-matter section
assignment = true
submit_check = false   # strict validation, enable before submission

[outlines]             # toggle each generated list
headings = true
figures = true

[bibliography]
source = "bib"         # "bib" | "yml"
citation_style = "numeric"  # "numeric" | "harvard"
```

### Glossary (`glossary.toml`)

```toml
[iso]
short = "ISO"
en = "International Organization for Standardization"
cs = "Mezinárodní organizace pro standardizaci"
# optional: glossary = "Definition text."
```

In document: `#trm("iso")` (first use expands, subsequent uses show short form). Plural: `#trmpl("iso")`. Czech case: `#trm("iso", case: 2)`.

### Programmatic API (no TOML)

```typ
#show: thesis_with.with(lang: "cs", draft: true, faculty: "fvl", ...)
```

### Annex Mode

```typ
#show: annex
= Příloha A
```

Switches heading/figure numbering to annex style.

## Typst Version

Requires Typst ≥ 0.14.0 (set in `typst.toml`).
