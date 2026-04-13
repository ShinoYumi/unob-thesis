/*
Modul: src/docs.typ
Co: Vývojářská dokumentace šablony UNOB Thesis.
Proč: Pomáhá novým i stávajícím přispěvatelům pochopit architekturu,
      pravidla a postupy bez nutnosti číst celý zdrojový kód.
Jak: Zobrazí se při `docs: true` v thesis.toml, před titulní stranou.
*/

#let _accent = rgb("#1a4a7a")
#set page(
  margin: (x: 2.5cm, y: 2.2cm),
  header: context {
    set text(size: 8pt, fill: luma(150))
    grid(
      columns: (1fr, 1fr),
      align(left)[Vývojářská dokumentace UNOB],
      align(right)[Odstraníte nastavením #raw("docs: false") v thesis.toml],
    )
    line(length: 100%, stroke: 0.4pt + luma(200))
  },
  footer: context {
    line(length: 100%, stroke: 0.4pt + luma(200))
    set text(size: 8pt, fill: luma(150))
    align(center)[Docs — strana #counter(page).display()]
  },
)
#set par(justify: true, first-line-indent: 0em)
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(0.6em)
  block(
    width: 100%,
    fill: _accent,
    inset: (x: 0.7em, y: 0.5em),
    radius: 3pt,
    text(fill: white, size: 14pt, weight: "bold", it.body),
  )
  v(0.4em)
}
#show heading.where(level: 2): it => {
  v(0.5em)
  text(fill: _accent, size: 12pt, weight: "bold", it.body)
  v(0.2em)
}
#show heading.where(level: 3): it => {
  v(0.3em)
  text(fill: _accent, size: 11pt, weight: "bold", it.body)
  v(0.1em)
}
#show heading.where(level: 4): it => {
  v(0.2em)
  text(fill: luma(60), size: 10pt, style: "italic", it.body)
  v(0.05em)
}

#align(center)[
  #v(1em)
  #block(
    fill: _accent,
    inset: (x: 2em, y: 1.2em),
    radius: 5pt,
    width: 80%,
  )[
    #text(fill: white, size: 18pt, weight: "bold")[VÝVOJÁŘSKÁ DOKUMENTACE UNOB]
    #v(0.3em)
    #text(fill: rgb("#a8c8f0"), size: 10pt)[Nastavte #raw("docs: false") v thesis.toml pro odstranění tohoto dokumentu]
  ]
  #v(1em)
]

Tento dokument je určen správcům a přispěvatelům šablony.
Uživatelský průvodce (pro autory prací) je v `guide.typ` (`guide: true`).

#v(0.5em)
_Přečti nejprve sekce Rychlý start a Architektura. Zbytek je referenční._

== Rychlý start pro nové přispěvatele

Chceš opravit chybu nebo přidat funkci? Tady začni.

=== 1. Sestav a zkontroluj

```bash
# Z kořenového adresáře repozitáře:
make get-fonts       # stáhne TeX Gyre fonty (jen poprvé)
make pdf             # zkompiluje template/thesis.typ → build/
make test            # spustí celou testovací sadu (vyžaduje tytanic)
```

=== 2. Najdi správný soubor

Nevíš, co upravit? Koukni na tabulku modulů níže a pak na checklist změny.

=== 3. Udělej změnu a ověř

```bash
make pdf             # ověř vizuální výstup
make test            # ověř, že nic nebreaks
```

Pokud vizuální výstup záměrně změníš (cover, layout), aktualizuj persistent reference:

```bash
make update-refs
```

== Architektura

=== Vstupní body

Šablona má tři způsoby použití — od nejjednoduššího po nejkomplexnější:

```typst
// 1. Nejčastější: načte vše z thesis.toml
#show: thesis

// 2. Programatické API bez TOML — vhodné pro testy
#show: thesis-with.with(lang: "cs", draft: true, faculty: "fvl", ...)

// 3. Plná kontrola — pro pokročilé nebo vývojáře šablony
#show: template.with(draft: ..., university: ..., thesis: ..., ...)
```

Vždy preferuj `thesis` nebo `thesis-with` — `template` je low-level a jeho signatura se může měnit.

=== Tok dat

```
thesis.toml
    ↓  config/loader.typ  (parsování a validace TOML)
    ↓  config/validation.typ  (striktní validace parametrů)
thesis-with.with(...)
    ↓  lib.typ  (orchestrace, normalizace, sestavení dokumentu)
    ↓  layout/*.typ  (vykreslení jednotlivých sekcí)
    ↓  PDF
```

=== Modulární vrstvy

#table(
  columns: (1.4fr, 2.2fr),
  stroke: (x: 0.4pt, y: 0.4pt),
  align: (left, left),
  table.header([*Soubor*], [*Odpovědnost a proč existuje*]),
  [`src/lib.typ`],
    [Jediný veřejný vstup. Exportuje `thesis`, `thesis-with`, `template` a všechny uživatelské funkce (`trm`, `acr`, `warning`, …). Důvod: stabilní API oddělené od interní implementace.],
  [`src/modules/config/loader.typ`],
    [Striktní načtení a validace `thesis.toml`. Mapuje TOML klíče na parametry `thesis-with`. Zachytí překlepy a legacy klíče s nápovědou.],
  [`src/modules/config/validation.typ`],
    [Validace parametrů předaných přímo (bez TOML). Odděleno od loaderu, aby fungovalo i pro programatické API.],
  [`src/modules/i18n/`],
    [Všechny překlady, názvy fakult, měst a typy prací. Změna textu → jen sem. Nikdy nepiš překlady do layout modulů.],
  [`src/modules/layout/styles.typ`],
    [Globální typografie, okraje, nadpisy, obrázky. Ovlivňuje celý dokument.],
  [`src/modules/layout/cover.typ`],
    [Titulní strana. Každá fakulta má vlastní layout. Viz sekce Cover stabilita.],
  [`src/modules/layout/frontmatter.typ`],
    [Zadání, poděkování, čestné prohlášení, abstrakty, úvod.],
  [`src/modules/layout/lists.typ`],
    [Obsah a volitelné seznamy (zkratky, pojmy, obrázky, tabulky, …).],
  [`src/modules/layout/annex.typ`],
    [Přílohy: přečísluje nadpisy (A, B, C) a obrázky (A.1, …).],
  [`src/modules/glossary/`],
    [Správa zkratek a pojmů. Parsuje TOML, spravuje runtime registry, filtruje pouze použité položky.],
  [`src/modules/notes.typ`],
    [Callout bloky (`#warning`, `#definition`, …). Barvy a titulky jsou data v `_palettes`, přizpůsobují se jazyku dokumentu.],
  [`src/modules/utils.typ`],
    [Sdílené utility: `has_value`, `has_person`, `coalesce`, `is_draft_mode`.],
)

== Pravidla API

=== Co nikdy nepřesouvat jinam
- Nové veřejné funkce přidávej *výhradně* do `src/lib.typ`.
- Pokud měníš signaturu veřejné funkce, proveď zpětně kompatibilní přechod nebo jasnou migraci s chybovou hláškou.

=== Zkratky a pojmy
Uživatelé mají k dispozici pouze:
```typst
#trm("iso")           // zkratka nebo pojem (automatická detekce)
#trmpl("iso")         // množné číslo
#acr("iso")           // vždy jen krátká forma
#trm("iso", case: 2)  // genitiv (čeština)
```
Jiné helpery neexistují. Interní implementace (`acronym`, `term`) jsou soukromé.

=== Draft vs. final mód
Draft mód se detekuje přes metadata uzel `<unob-layout-draft>`, ne přes přímý parametr:
```typst
// Správně — funguje i v annex a jiných kontextech:
context is_draft_mode()

// Špatně — parametr není vždy dostupný:
draft == true
```

== Kontrakt glosáře a TOML

Vstup je sjednocen v `template/glossary.toml`:

```toml
[iso]
short   = "ISO"
cs      = "Mezinárodní organizace pro standardizaci"
en      = "International Organization for Standardization"
# Přidej `glossary` → záznam se stane pojmem (ne jen zkratkou):
# glossary = "Definice pojmu…"
```

Modul `src/modules/glossary/` musí garantovat:

- Vyhledávání klíčů bez ohledu na velikost písmen (`key` i `short`).
- Výpis pouze *použitých* položek — nepoužité se netisknou.
- První výskyt: `Mezinárodní organizace pro standardizaci (ISO)`.
- Další výskyty: `ISO`.
- Proklik z výskytu do seznamu zkratek (pokud je seznam přítomný).

=== Časté chyby při rozšiřování glosáře

*Přidáváš nový typ vstupu?* Uprav `parse.typ` — funkce `normalize-acronyms-input` a `normalize-terms-input` sdílí `_normalize_entries_input` pipeline. Přidej větev tam.

*Měníš strukturu záznamu?* Ověř `validate.typ` (kontrola duplikátů a zakázaných znaků) a `runtime.typ` (registrace do glossarium).

== Cover stabilita

`src/modules/layout/cover.typ` musí dodržovat layout invarianty, jinak persistent testy selžou.

*Proč jsou invarianty důležité?* Titulní strana je nejviditelnější část práce. Každá vizuální odchylka (i 1 px) způsobí selhání persistent testů a potenciálně nesplnění požadavků fakulty.

=== Invarianty

- První čtyři řádky mají vždy rezervované místo — logo se nesmí posunout.
- Prázdný `programme` nebo `specialisation` nesmí pohnout logem.
- Logo má pevnou výšku `6.71cm`.
- Vertikální rytmus řádků je 1,5násobek velikosti písma.

=== Postup při změně coveru

1. Uprav layout v `cover.typ`.
2. Spusť `make pdf` a vizuálně ověř všechny čtyři fakulty (fvl, fvt, vlf, uo).
3. Spusť `make test` — persistent testy selžou, protože reference jsou staré.
4. Spusť `make update-refs` pro aktualizaci referencí.
5. Commitni spolu s novými PNG soubory z `tests/phase/persistent-*/ref/`.

== Testování

=== Jak spustit testy

```bash
make test            # všechny fáze
make test PHASE=2    # jen compile-only fáze
TT=/path/to/tt make test  # vlastní binárka tytanic
```

=== Fáze testů

#table(
  columns: (auto, 1fr, 1.5fr),
  stroke: (x: 0.4pt, y: 0.4pt),
  align: (left, left, left),
  table.header([*Fáze*], [*Co testuje*], [*Kdy selže*]),
  [1 — Grammar],    [Syntaxe výrazů tytanic],         [Chyba v test expression],
  [2 — Compile],    [Úspěšná kompilace bez pádu],     [Typst error, panic, assertion],
  [3 — Ephemeral],  [Vizuální shoda in-memory],        [Změna layoutu v draft módu],
  [4 — Persistent], [Vizuální shoda s PNG referencemi],[Změna cover nebo finálního layoutu],
  [5 — Full],       [Kompletní sada],                  [Cokoli z výše],
)

=== Jak přidat nový test

1. Vytvoř adresář `tests/phase/<nazev-testu>/`.
2. Vlož `test.typ` — minimální dokument, který testuje konkrétní funkci.
3. Pro persistent test přidej `ref/` s PNG referencemi (`make update-refs`).
4. Přidej odpovídající anotaci do `test.typ`:
   ```typst
   // >>> compile-only()
   ```

== Checklist při změně kódu

Tento checklist ti ušetří zbytečné opravy.

+ *Uprav modul(y)* v `src/modules/*`.
+ *Zkontroluj API* v `src/lib.typ` — přidáváš/měníš veřejnou funkci? Dodržuješ zpětnou kompatibilitu?
+ *Překlady* — mění se texty nebo chybové hlášky? Aktualizuj `src/modules/i18n/data.typ`.
+ *Kompilace* — `make pdf`. Vizuálně zkontroluj výstup.
+ *Testy* — `make test`. Selžou persistent testy? Spusť `make update-refs` a commitni PNG.
+ *Docs* — Mění se chování pro uživatele? Aktualizuj `src/modules/guide.typ`. Mění se interní architektura? Aktualizuj tento soubor.

== Časté otázky (FAQ)

*Proč funkce přijímá 10+ parametrů místo importu?*
Typst neumožňuje přímý přístup k importovaným funkcím uvnitř `context` bloků v jiných modulech. Proto se helpery (`has_value`, `format_name`, …) předávají jako parametry do `render_*` funkcí.

*Proč je `src/modules/glossary/index.typ` prázdný (jen re-export)?*
Umožňuje čistší import: `#import "modules/glossary/index.typ": trm` místo přímého importu z `glossary.typ`. Odděluje veřejné API od interní implementace.

*Jak přidat novou fakultu?*
1. Přidej barvu do `i18n/data.typ` (`faculty_colors`).
2. Přidej jméno a město do `faculty_names` a `city_names`.
3. Přidej logo do `resources/logos/`.
4. Přidej layout větev do `layout/cover.typ`.
5. Přidej persistent test pro novou fakultu.

*Proč selžou persistent testy po upgradu Typstu?*
Typst může mírně změnit renderování písma nebo layoutu. Vizuálně ověř, zda jsou změny očekávané, pak spusť `make update-refs`.

*Kde nahlásit chybu nebo navrhnout funkci?*
Otevři issue na GitHub repozitáři projektu.

== Známá omezení

- *PDF metadata* — Typst aktuálně nepodporuje kompletní sadu custom PDF/A metadat požadovanou některými archivními workflow.
- *České pádování* — Heuristika v `trm(..., case: ...)` je záměrně konzervativní (primárně skloňuje první slovo). Výsledek může být nesprávný u víceslovných zkratek.
- *Diff* — Funkce `diff.typ` (palimset) porovnává dokumenty vizuálně (pixel-level), ne sémanticky. Není vhodná pro sledování změn ve zdrojovém kódu.
