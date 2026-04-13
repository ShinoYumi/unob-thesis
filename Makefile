TYPST ?= typst
ROOT ?= .
SRC ?= template/thesis.typ
CFG ?= template/thesis.toml
OUT_DIR ?= build
TYPE ?= auto
OPEN ?= 0
FONT_PATH ?= resources/fonts

ifeq ($(OS),Windows_NT)
  PLATFORM := windows
  PS := powershell -NoProfile -ExecutionPolicy Bypass
else
  PLATFORM := unix
  SHELL := /bin/sh
endif

.DEFAULT_GOAL := pdf

.PHONY: help check get-fonts pdf iso print-output watch test update-refs clean distclean

help: ## Zobrazí dostupné targety a jejich popis
ifeq ($(PLATFORM),windows)
	@$(PS) -Command "$$lines = Get-Content -LiteralPath 'Makefile'; Write-Output 'UNOB Thesis - Make targets'; Write-Output ''; foreach ($$line in $$lines) { if ($$line -match '^([A-Za-z0-9_.-]+):.*##\s*(.+)\s*$$') { '{0,-14} {1}' -f $$matches[1], $$matches[2] } }"
else
	@awk 'BEGIN {FS = ":.*## "; print "UNOB Thesis - Make targets\n"} /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
endif

check: ## Ověří dostupnost nástrojů a vstupních souborů
ifeq ($(PLATFORM),windows)
	@$(PS) -Command "if (-not (Test-Path -LiteralPath 'scripts/make-pdf.ps1')) { Write-Error 'scripts/make-pdf.ps1 nenalezen'; exit 2 }"
		@$(PS) -File scripts/make-pdf.ps1 -Action check -Typst "$(TYPST)" -Root "$(ROOT)" -Src "$(SRC)" -Cfg "$(CFG)" -OutDir "$(OUT_DIR)" -FontPath "$(FONT_PATH)" -Type "$(TYPE)" -Open "$(OPEN)"
else
	@[ -x scripts/make-pdf.sh ] || { echo "ERROR: scripts/make-pdf.sh není spustitelný"; exit 2; }
		@TYPST="$(TYPST)" ROOT="$(ROOT)" SRC="$(SRC)" CFG="$(CFG)" OUT_DIR="$(OUT_DIR)" FONT_PATH="$(FONT_PATH)" TYPE="$(TYPE)" OPEN="$(OPEN)" scripts/make-pdf.sh check
endif

get-fonts: ## Stáhne TeX Gyre fonty do resources/fonts a rozbalí .otf
ifeq ($(PLATFORM),windows)
	@$(PS) -Command "if (-not (Test-Path -LiteralPath 'scripts/get-fonts.ps1')) { Write-Error 'scripts/get-fonts.ps1 nenalezen'; exit 2 }"
		@$(PS) -File scripts/get-fonts.ps1 -OutDir "$(FONT_PATH)"
else
		@OUT_DIR="$(FONT_PATH)" scripts/get-fonts.sh
endif

pdf: check ## Kompiluje PDF (TYPE=auto|draft|final, OPEN=0|1)
ifeq ($(PLATFORM),windows)
		@$(PS) -File scripts/make-pdf.ps1 -Action compile -Typst "$(TYPST)" -Root "$(ROOT)" -Src "$(SRC)" -Cfg "$(CFG)" -OutDir "$(OUT_DIR)" -FontPath "$(FONT_PATH)" -Type "$(TYPE)" -Open "$(OPEN)"
else
		@TYPST="$(TYPST)" ROOT="$(ROOT)" SRC="$(SRC)" CFG="$(CFG)" OUT_DIR="$(OUT_DIR)" FONT_PATH="$(FONT_PATH)" TYPE="$(TYPE)" OPEN="$(OPEN)" scripts/make-pdf.sh compile
endif

iso: pdf ## Alias pro `pdf`

print-output: check ## Vypíše cílový output soubor pro zadaný TYPE
ifeq ($(PLATFORM),windows)
		@$(PS) -File scripts/make-pdf.ps1 -Action output -Typst "$(TYPST)" -Root "$(ROOT)" -Src "$(SRC)" -Cfg "$(CFG)" -OutDir "$(OUT_DIR)" -FontPath "$(FONT_PATH)" -Type "$(TYPE)" -Open "$(OPEN)"
else
		@TYPST="$(TYPST)" ROOT="$(ROOT)" SRC="$(SRC)" CFG="$(CFG)" OUT_DIR="$(OUT_DIR)" FONT_PATH="$(FONT_PATH)" TYPE="$(TYPE)" OPEN="$(OPEN)" scripts/make-pdf.sh output
endif

watch: check ## Sleduje změny a průběžně kompiluje (TYPE=auto|draft|final)
ifeq ($(PLATFORM),windows)
		@$(PS) -File scripts/make-pdf.ps1 -Action watch -Typst "$(TYPST)" -Root "$(ROOT)" -Src "$(SRC)" -Cfg "$(CFG)" -OutDir "$(OUT_DIR)" -FontPath "$(FONT_PATH)" -Type "$(TYPE)" -Open "$(OPEN)"
else
		@TYPST="$(TYPST)" ROOT="$(ROOT)" SRC="$(SRC)" CFG="$(CFG)" OUT_DIR="$(OUT_DIR)" FONT_PATH="$(FONT_PATH)" TYPE="$(TYPE)" OPEN="$(OPEN)" scripts/make-pdf.sh watch
endif

test: ## Spustí testovací fáze
	scripts/test-phases.sh

update-refs: ## Aktualizuje reference pro persistent testy
	scripts/update-phase-refs.sh

clean: ## Smaže jen dočasné .tmp-* soubory v build/
ifeq ($(PLATFORM),windows)
	@$(PS) -Command "New-Item -ItemType Directory -Force -Path '$(OUT_DIR)' | Out-Null; Get-ChildItem -LiteralPath '$(OUT_DIR)' -File -Filter '.tmp-*' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue"
else
	@mkdir -p "$(OUT_DIR)"
	@rm -f "$(OUT_DIR)"/.tmp-*.toml "$(OUT_DIR)"/.tmp-*.typ
endif

distclean: ## Smaže celý build/ adresář
ifeq ($(PLATFORM),windows)
	@$(PS) -Command "if (Test-Path -LiteralPath '$(OUT_DIR)') { Remove-Item -LiteralPath '$(OUT_DIR)' -Recurse -Force }"
else
	@rm -rf "$(OUT_DIR)"
endif
