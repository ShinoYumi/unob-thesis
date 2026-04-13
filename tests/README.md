# UNOB Thesis test suite (tytanic)

Testy jsou připravené pro `tytanic` (`tt`) a ověřují jednotlivé fáze:

1. výběr testů přes test-set výrazy (grammar)
2. compile-only testy
3. ephemeral testy
4. persistent testy
5. full run bez skip testů

## Regression matrix

Sada pokrývá kombinace, které jsou citlivé na regresi:

- `draft: true` / `draft: false`
- `lang: cs` / `lang: en`
- glosář zapnutý / vypnutý
- režim příloh (`#show: annex`)
- stabilita coveru s vyplněným i prázdným programem/specializací
- used-only seznam zkratek (testované přes query/assert)

## Spuštění

```bash
scripts/test-phases.sh
```

Pokud nemáte `tt` v `PATH`, nastavte binárku přes proměnnou `TT`:

```bash
TT=./.tools/tt scripts/test-phases.sh
```

Poznámka k fontům: skript defaultně používá `--use-system-fonts`, aby byly dostupné i lokálně nainstalované fonty (např. TeX Gyre). Chování můžete přepsat přes `TT_FONT_ARGS`, například:

```bash
TT_FONT_ARGS="" scripts/test-phases.sh
TT_FONT_ARGS="--use-system-fonts --font-path /cesta/k/fontum" scripts/test-phases.sh
```

## Aktualizace referencí (persistent)

```bash
scripts/update-phase-refs.sh
```

## Test-set výrazy (použité v testech)

- `compile-only() | ephemeral()`
- `compile-only() & skip()`
- `compile-only() ^ skip()`
- `r:^phase/ & !skip()`
- `(r:^phase/ ~ skip()) | template()`

Tyto výrazy odpovídají syntaxi a operátorům z dokumentace:
https://typst-community.github.io/tytanic/reference/test-sets/grammar.html

`scripts/test-phases.sh` neověřuje fixní počty testů, ale invariants:

- `all() = all(skip-default) + skip()`
- XOR identita: `A ^ B = (A ~ B) | (B ~ A)`
- kontrola, že skip sample a template set jsou nalezené
