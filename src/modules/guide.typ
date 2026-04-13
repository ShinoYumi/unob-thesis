// Guide: Průvodce šablonou — zobrazí se před titulní stranou, odstraní se nastavením guide: false.
#let _guide-accent = rgb("#1a4a7a")
#set page(
  margin: (x: 2.5cm, y: 2.2cm),
  header: context {
    set text(size: 8pt, fill: luma(150))
    grid(
      columns: (1fr, 1fr),
      align(left)[Průvodce šablonou UNOB],
      align(right)[Odstraníte nastavením #raw("guide: false") v thesis.toml],
    )
    line(length: 100%, stroke: 0.4pt + luma(200))
  },
  footer: context {
    line(length: 100%, stroke: 0.4pt + luma(200))
    set text(size: 8pt, fill: luma(150))
    align(center)[Průvodce — strana #counter(page).display()]
  },
)
#set par(justify: true, first-line-indent: 0em, hanging-indent: 0em)
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(0.6em)
  block(
    width: 100%,
    fill: _guide-accent,
    inset: (x: 0.7em, y: 0.5em),
    radius: 3pt,
    text(fill: white, size: 14pt, weight: "bold", it.body),
  )
  v(0.4em)
}
#show heading.where(level: 2): it => {
  v(0.5em)
  text(fill: _guide-accent, size: 12pt, weight: "bold", it.body)
  v(0.2em)
}
#show heading.where(level: 3): it => {
  v(0.3em)
  text(fill: _guide-accent, size: 11pt, weight: "bold", it.body)
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
    fill: _guide-accent,
    inset: (x: 2em, y: 1.2em),
    radius: 5pt,
    width: 80%,
  )[
    #text(fill: white, size: 18pt, weight: "bold")[PRŮVODCE ŠABLONOU UNOB]
    #v(0.3em)
    #text(fill: rgb("#a8c8f0"), size: 10pt)[Nastavte #raw("guide: false") v thesis.toml pro odstranění tohoto průvodce]
  ]
  #v(1em)
]

= Přehled a základní návod

==== Obsah průvodce
- Nastavení šablony (`thesis.toml`)
- Práce s glossářem
- Callout bloky / poznámky
- Draft mód a TODO
- Přílohy (annex mód)
- Diff — porovnání verzí
- Sestavení (build)
- Typografické zásady a ukázky zápisu

== Nastavení šablony — `thesis.toml`

Veškerá metadata práce se zadávají do souboru `template/thesis.toml`. Šablona se spouští řádkem `#show: thesis` v `thesis.typ`, který automaticky načte konfiguraci z `thesis.toml`.

Přehled polí `thesis.toml`:

```toml
lang = "cs"          # Jazyk výstupu: "cs" (čeština) nebo "en" (angličtina)
draft = true         # true = pracovní režim, false = finální výstup
faculty = "fvl"      # Fakulta: "fvl", "fvt", "vlf", "uo"
program = "Řízení a použití ozbrojených sil"       # Název studijního programu
specialization = "Management informačních zdrojů"  # Název studijní specializace

[thesis]
type = "master"      # Typ práce: "bachelor", "master", "doctoral"
title = "Název práce"

[author]
prefix = "rtm."      # Hodnost nebo titul před jménem
name   = "Jan"
surname = "Novák"
# suffix = "Ph.D."  # Titul za jménem — klíč vynech, pokud ho není
sex = "M"            # "M" nebo "F" — vliv na gramatiku čestného prohlášení

[supervisor]         # Vedoucí práce (bachelor, master) nebo školitel (doctoral)
prefix = "pplk. Ing."
name   = "Jana"
surname = "Nováková"
suffix = "Ph.D."
sex = "F"

[advisor]            # Odborný konzultant / první školitel-specialista (volitelné)
prefix = "Mgr."
name   = "Jan"
surname = "Novák"

[co_supervisor]      # Druhý školitel-specialista — pouze doctoral (volitelné)
prefix = "Ing."
name   = "František"
surname = "Novák"

[lists]
assignment    = true   # Zařadit listy zadání (front.png / back.png)
acknowledgement = true
declaration   = true
ai_used       = true   # Bylo v práci použito generativní AI?
acronyms      = true   # Zobrazit seznam zkratek
terms         = true   # Zobrazit seznam pojmů
guide         = false  # Tento průvodce — před odevzdáním vypnout
submit_check  = false  # Před odevzdáním nastavit na true (striktní validace)

[outlines]
headings   = true    # Obsah
figures    = true    # Seznam obrázků
tables     = true    # Seznam tabulek
acronyms   = false   # Seznam zkratek (alternativa k [lists] acronyms)
terms      = false   # Seznam pojmů
equations  = false   # Seznam rovnic
listings   = false   # Seznam výpisů kódu

[bibliography]
source         = "bib"     # "bib" nebo "yml"
citation_style = "numeric" # "numeric" nebo "harvard"

[theme]
color           = true   # Hlavní přepínač — false = celý dokument ČB
notes_colored   = true   # Barevné callout bloky
links_colored   = true   # Barevné hypertextové odkazy
faculty_colored = true   # Barva fakulty jako záložní barva odkazů
# faculty_color = "#808205"  # Vlastní barva fakulty (hex, volitelné)
# link_color    = "#2D4979"  # Vlastní barva odkazů (má přednost, volitelné)
```

Základní typy hodnot v Typstu:
```typ
Text (String) – "text".  Prostý řetězec, bez formátování.
Obsah (Content) – [text]. Formátovaný blok — odstavce, seznamy, inline kód.
Přepínač (Boolean) – true | false.
```

== Metadata bloky v thesis.typ

Abstrakt a klíčová slova lze zapsat přímo v `thesis.typ` pomocí speciálních bloků — tyto hodnoty mají přednost před hodnotami z `thesis.toml`:

```typ
#abstract-cs[Český abstrakt práce. Stručný popis tématu, cílů a výsledků.]
#abstract-en[English abstract. Brief description of topic, goals and results.]
#keywords-cs("klíčové slovo 1, klíčové slovo 2, klíčové slovo 3")
#keywords-en("keyword 1, keyword 2, keyword 3")
```

Bloky lze umístit kdekoliv před konec dokumentu — šablona si je sama vyhledá.

== Programatické API (bez TOML)

Pro pokročilé použití a testy lze šablonu inicializovat přímo v Typstu bez `thesis.toml`. Funkce #raw("thesis-with") přijímá stejné parametry jako konfigurační soubor:

```typ
#import "@preview/unob-thesis:1.0.0": thesis-with, person

#show: thesis-with.with(
  lang: "cs",                    // "cs" nebo "en"
  draft: false,
  faculty: "fvl",                // "fvl" | "fvt" | "vlf" | "uo"
  programme: [Řízení a použití ozbrojených sil],
  specialisation: [Management informačních zdrojů],
  thesis: (
    type: "master",              // "bachelor" | "master" | "doctoral"
    title: [Název práce],
  ),
  author: person(
    prefix: "rtm.",
    name: "Jan",
    surname: "Novák",
    suffix: none,                // none nebo "Ph.D."
    sex: "M",                    // "M" nebo "F"
  ),
  supervisor: person(
    prefix: "pplk. Ing.",
    name: "Jana",
    surname: "Nováková",
    suffix: "Ph.D.",
    sex: "F",
  ),
  // first_advisor: person(...),  // Odborný konzultant (volitelné)
  // second_advisor: person(...), // Druhý konzultant (volitelné)
  assignment: false,
  acknowledgement: false,        // false nebo [Text poděkování...]
  declaration: true,
  ai_used: false,
  acronyms: true,
  terms: true,
  abstract: (
    czech: [Obsah abstraktu v češtině.],
    english: [Abstract content in English.],
  ),
  keywords: (
    czech: "klíčové slovo 1, klíčové slovo 2",
    english: "keyword 1, keyword 2",
  ),
  outlines: (
    headings: true,
    figures:  true,
    tables:   true,
    acronyms: false,
    terms:    false,
    equations: false,
    listings:  false,
  ),
  theme: (
    color: true,
    notes_colored: true,
    links_colored: true,
    faculty_colored: true,
  ),
  introduction: [],              // [] = výchozí text, nebo [Vlastní úvod...]
  guide: false,
  docs: false,
  submit_check: false,
)

= ÚVOD
...
```

== Práce s glossářem — `glossary.toml`

Zkratky a pojmy se definují v souboru `template/glossary.toml`. Šablona automaticky generuje seznam zkratek a seznam pojmů.

==== Struktura záznamu
```toml
[iso]                  # klíč — píše se malými písmeny, jen písmena/číslice/pomlčka
short   = "ISO"        # zobrazovaná zkratka
cs      = "Mezinárodní organizace pro standardizaci"  # český rozpad
en      = "International Organization for Standardization"  # anglický rozpad
glossary = "Definice nebo rozšířený popis (nepovinné, zobrazí se v seznamu pojmů)"
```

- Záznamy s `glossary` jsou považovány za *pojmy* (terms), ostatní za *zkratky* (acronyms).
- Stačí vyplnit `cs` nebo `en` (nebo obojí) — jazyk výstupu se přizpůsobí nastavení `lang`.

==== Použití v textu
```typ
#trm("iso")             // první výskyt: "Mezinárodní organizace pro standardizaci (ISO)"
                        // další výskyty: "ISO"
#acr("iso")             // vždy jen zkratka: "ISO"
#trmpl("iso")           // množné číslo (přidá -y/-i dle kontextu)
#trm("iso", style: plural)  // explicitní množné číslo
#trm("iso", case: 2)    // genitiv (pro češtinu)
```

== Callout bloky / poznámky

Šablona nabízí sadu vizuálně odlišených bloků pro zdůraznění různých typů obsahu.

==== Dostupné bloky
```typ
#warning[Text varování]           // Amber — důležité upozornění
#solution[Text doporučení]        // Emerald — doporučený postup
#idea[Nápad nebo postřeh]         // Sky — myšlenka
#definition[Definice pojmu]       // Indigo — definice
#context-note[Kontextová poznámka] // Slate — širší kontext, pozadí
#example[Ukázkový příklad]        // Teal — příklad
#method-note[Metodická poznámka]  // Rose — metodika
#interpretation[Interpretace]     // Violet — výklad výsledků
#summary[Shrnutí kapitoly]        // Emerald — shrnutí
#literature[Přehled literatury]   // Sky — literaturní přehled
#todo-note[Poznámka k dopracování] // Orange — viditelná pouze v draft módu
```

==== České aliasy
```typ
#varovani[]  #reseni[]  #napad[]  #definice[]
#kontext[]   #priklad[] #metodicka-poznamka[]
#interpretace[]  #shrnuti[]  #literatura[]
```

== Draft mód a TODO poznámky

Pracovní (draft) mód aktivujete nastavením `draft = true` v `thesis.toml`.

*V draft módu:*
- záhlaví dokumentu zobrazuje banner DRAFT
- stránky mají zjednodušené okraje (vhodné pro tisk A4)
- jsou viditelné `#todo` poznámky v pravém okraji

```typ
#todo[Zkontrolovat citace v této sekci.]
#todo[Doplnit statistická data.]

// Na konci dokumentu (volitelně) — přehled všech TODO:
#todo-outline()
```

Před finálním odevzdáním nastavte `draft = false` — TODO poznámky zmizí a `#todo-outline()` se nevykreslí.

== Přílohy — Annex mód

Přílohy se zapisují za bibliografii pomocí `#show: annex`:

```typ
#show-bibliography()

#show: annex
= NÁZEV PRVNÍ PŘÍLOHY

Text první přílohy...

= NÁZEV DRUHÉ PŘÍLOHY

Text druhé přílohy...
```

- Nadpisy příloh se číslují písmeny (A, B, C, …).
- Obrázky a tabulky v přílohách mají vlastní čítač (A.1, A.2, …).
- Přílohy se automaticky zobrazí v obsahu s odlišným prefixem.

== Diff — porovnání verzí

Diff umožňuje vedoucímu práce přehledně vidět, co se mezi verzemi změnilo.

==== Workflow
```
1. Pracujete v souboru  thesis.typ  (aktuální verze)
2. Před odesláním revize uložte kopii starší verze:
      cp thesis.typ thesis-prev.typ
3. Proveďte změny v  thesis.typ
4. Zkompilujte diff.typ → vznikne PDF s vyznačenými změnami
```

```typ
// diff.typ — tento soubor není třeba upravovat
#import "@preview/palimset:0.1.0": *

#diff-content(
  include "thesis-prev.typ",   // starší verze (základ srovnání)
  include "thesis.typ"         // aktuální verze (co přibylo/ubylo)
)
```

==== Interpretace výstupu
- *Zeleně* zvýrazněný text byl *přidán* v nové verzi.
- *Červeně* zvýrazněný text byl *odebrán* ze starší verze.
- Diff je vizuální (pixel-level porovnání stránek) — nezáleží na struktuře zdrojového kódu.

Pozn. Pokud chcete přehledný diff pro průběžné konzultace, je vhodné `thesis-prev.typ` přepisovat vždy před odesláním nové verze vedoucímu.

== Sestavení — build

==== Pomocí Makefile (doporučeno)
```bash
make pdf              # Zkompiluje thesis.typ → build/
make watch            # Průběžná kompilace při uložení souboru
make pdf TYPE=draft   # Vynutit draft mód (bez ohledu na thesis.toml)
make pdf TYPE=final   # Vynutit finální mód
make get-fonts        # Stáhnout fonty TeX Gyre do resources/fonts/
make check            # Ověřit dostupnost nástrojů a vstupních souborů
make clean            # Smazat dočasné soubory
```

==== Přímé volání Typstu
```bash
# z kořenového adresáře repozitáře:
typst compile --root . template/thesis.typ
typst compile --root . template/diff.typ
typst watch   --root . template/thesis.typ
```

Výstupní soubory se ukládají do adresáře `build/` ve formátu:
`YYYY-MM-DD - <Název práce> - Draft.pdf` (nebo Final.pdf).

== Typografické zásady a ukázky zápisu

*1. Kapitola – TEORETICKÁ ČÁST / ANALÝZA SOUČASNÉHO
STAVU*

Vyberte pouze jeden nadpis.

Úvod ke kapitole v rozsahu 3–5 řádků, který představuje náplň kapitoly. Každá kapitola začíná na nové stránce.

Text se člení na hlavní kapitoly, podkapitoly (např. 1.1) a oddíly (např. 1.1.1), další členění se nedoporučují.

Název kapitoly volíte pouze jeden v závislosti na obsahu práce.

Jednotlivé oddíly kapitoly by měly být z hlediska rozsahu vyvážené (přibližně stejně dlouhé).

Podle Pravidel českého pravopisu se nepíší neslabičné předložky v, s, z, k na konec řádku, podle typografické normy jednopísmenná slova (předložky a spojky a, i, o, u) a jakékoli jednoslabičné výrazy (např. ve, ke, ku, že, na, do, od, pod). Nepoužívejte automatické dělení slov. Spojení slov lze provést pomocí tzv. vlny #"~" (Windows: alt + 126, GNU/Linux Pravý Alt + 126, MacOS: option + 5) příklad Text a~spojený text.

V případě používání výčtu je možné položky výčtu označovat číslicemi, písmeny abecedy, pomlčkami, odrážkami nebo jinými grafickými prvky. Bližší úpravu a zásady psaní položek výčtu naleznete na http://prirucka.ujc.cas.cz/?id=870.

Doporučuje se, aby na tabulky a obrázky byly zařazeny poblíž jejich první citace v textu. Při citaci v textu, musí číslům tabulek nebo obrázků předcházet nebo po nich následovat slova obrázek nebo tabulka. Za obrázky je považována kresba, graf, fotografie, mapa. Tabulky a obrázky musí být čitelné.

U každého obrázku a tabulky musí být uveden krátký horizontální a neorámovaný popisný text. Popisný text tabulky musí být napsán nad tabulkou za arabskou číslicí přidělenou tabulce. Legenda k obrázku musí být umístěna pod obrázkem. Legenda
k obrázku musí být umístěna za arabskou číslici přidělenou obrázku. U nepůvodních obrázků a tabulek se uvádí pramen. Obrázky a tabulky se číslují odděleně a posloupně.

==== Praktická ukázka nejčastějších zápisů:

==== 1 NÁZEV KAPITOLY
==== 1.1 Podkapitola
==== 1.1.1 Oddíl
==== Čtvrtý řád – pokud je potřeba, nemá číslování

==== Zápis
```typst
= NÁZEV KAPITOLY
== Podkapitola
=== Oddíl
==== Čtvrtý řád – pokud je potřeba, nemá číslování
```
==== Obrázek s titulkem
Pozn. Pokud se nevleze společně se zdrojem na jednu stranu můžeme jej odsadit s pomocí `#colbreak()` (column break).
#figure(
  caption: [Název obrázku],
  image(
    "../../thumbnail.png",
    width: 5cm,
    height: 5cm,
  ),
)<obr:Můj_obrázek>
Zdroj: vlastní

Reference na @obr:Můj_obrázek, nebo také na @obr:Můj_obrázek[cokoliv co napišu]

==== Zápis

```typ
#figure(
  caption: [Název obrázku], // Titulek
  image(
    "obrazek.png", // Cesta k obrázku
    width: 5cm, // Šířka
    height: 5cm,  // Výška
  ),
)<obr:Můj_obrázek> // Vytvoření štítku k odkazování
Zdroj: @klíč-citace // Zdroj z bibliografie
Reference na @obr:Můj_obrázek, nebo také na @obr:Můj_obrázek[cokoliv co napišu] // Odkázání na obrázek. Provázáno přes proklik. V hranatých závorkách lze upravit název.
```

==== *Tabulka s titulkem*
#figure(
  caption: [Název tabulky],
  table(
    columns: 3,
    rows: 3,
    table.header([Záhlaví Jedna], [Záhlaví dva], [Záhlaví tři]),
    [První buňka], [Druhá buňka], [Třetí buňka],
    [Čtvrtá buňka], [Pátá buňka], [Šestá buňka],
    table.footer([Zápatí jedna], [Zápatí dva], [Zápatí tři]),
  ),
)<tab:Moje_tabulka>
@tab:Moje_tabulka
==== Zápis
```typ
#figure(
  caption: [Název tabulky], // Titulek
    table(
      columns: 3, // Počet sloupců
      rows: 3, // Počet řádků
      table.header([Záhlaví Jedna], [Záhlaví dva], [Záhlaví tři]), // Záhlaví
      [První buňka], [Druhá buňka], [Třetí buňka], // Tělo tabulky
      [Čtvrtá buňka], [Pátá buňka], [Šestá buňka],
      table.footer([Zápatí jedna], [Zápatí dva], [Zápatí tři] // Zápatí
    )
  )
)<tab:Moje_tabulka>
@tab:Moje_tabulka
```

==== Matematika – inline
Text $a+b=3$ Pokračování textu

==== Zápis
```typ
$a+b=3$
```
==== Bloková

Text
$
  x = (-b plus.minus sqrt(b^2 - 4 a c)) / (2a)
$
Pokračování textu
==== Zápis
```typ
$
x = (-b plus.minus sqrt(b^2 - 4 a c)) / (2a)
$
```
==== Kód
#figure(
  caption: [Název kódu/výpisu],
  ```python
  print("Hello, World!")
  ```,
)
==== Zápis
````typ
  #figure(
    caption: [Název kódu/výpisu],
  ```python
    print("Hello, World!")
  ```
  )
````
