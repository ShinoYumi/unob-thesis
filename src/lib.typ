/*
Modul: src/lib.typ
Co: Hlavní veřejné API šablony závěrečných prací.
Proč: Udržuje konfiguraci, validaci i skládání dokumentu na jednom místě.
Jak:
1) Importuje dílčí moduly (i18n, cover, frontmatter, listy, glosář, styly).
2) Normalizuje vstupy (osoby, zkratky, pojmy, režim).
3) Validuje konfiguraci a aplikuje globální styl.
4) Sestaví dokument ve stabilním pořadí (cover -> frontmatter -> listy -> tělo).
*/

/* ==========================================
 * 1. Importy
 * ========================================== */
#import "modules/i18n/index.typ": t, faculty-name as i18n-faculty-name, city-name as i18n-city-name, thesis-type-name as i18n-thesis-type-name, normalize-thesis-type as i18n-normalize-thesis-type
#import "modules/layout/styles.typ": apply-base-styles, apply-heading-styles, apply-figure-styles
#import "modules/layout/cover.typ": render-cover
#import "modules/layout/frontmatter.typ": render-assignment, render-acknowledgement, render-declaration, render-abstracts, render-introduction
#import "modules/layout/lists.typ": render-lists
#import "modules/config/validation.typ": validate-config, validate-submit-check
#import "modules/layout/annex.typ": annex
#import "modules/layout/drafting.typ": todo as todo-impl, todo-outline as todo-outline-impl, setup-draft-todos
#import "modules/glossary/index.typ": glossary-show, normalize-glossary-input, glossary-to-acronyms, glossary-to-terms, normalize-acronyms-input, normalize-terms-input, has-used-acronyms, has-used-terms, generate-acronyms-list, generate-terms-list, init-glossary-runtime, validate-glossary-registry, singular as singular-style-impl, plural as plural-style-impl, first as first-style-impl, first-plural as first-plural-style-impl, acr as acr-impl, trm as trm-impl, trmpl as trmpl-impl
#import "modules/config/loader.typ": load-thesis-from-toml
#import "modules/utils.typ": has-value, has-person, coalesce
#import "modules/notes.typ": emptyblock as emptyblock-impl, callout as callout-impl, note-outline as note-outline-impl, setup-notes-color as setup-notes-color-impl, warning as warning-impl, solution as solution-impl, idea as idea-impl, todo-note as todo-note-impl, definition as definition-note-impl, context-note as context-note-impl, example as example-note-impl, method-note as method-note-impl, interpretation as interpretation-impl, summary as summary-note-impl, literature as literature-note-impl, varovani as varovani-impl, reseni as reseni-impl, napad as napad-impl, definice as definice-impl, kontext as kontext-impl, priklad as priklad-impl, metodicka-poznamka as metodicka-poznamka-impl, interpretace as interpretace-impl, shrnuti as shrnuti-impl, literatura as literatura-impl

// API: Veřejné aliasy pro práci se zkratkami a pojmy.
// Proč: Udržují stabilní rozhraní i při interních změnách v `modules/glossary.typ`.
#let acr = acr-impl
#let trm = trm-impl
#let trmpl = trmpl-impl
#let singular = singular-style-impl
#let plural = plural-style-impl
#let first = first-style-impl
#let first-plural = first-plural-style-impl
#let todo = todo-impl
#let todo-outline = todo-outline-impl
#let emptyblock = emptyblock-impl
#let callout = callout-impl
#let note-outline = note-outline-impl
#let warning = warning-impl
#let solution = solution-impl
#let idea = idea-impl
#let todo-note = todo-note-impl
#let definition = definition-note-impl
#let context-note = context-note-impl
#let example = example-note-impl
#let method-note = method-note-impl
#let interpretation = interpretation-impl
#let summary = summary-note-impl
#let literature = literature-note-impl
#let varovani = varovani-impl
#let reseni = reseni-impl
#let napad = napad-impl
#let definice = definice-impl
#let kontext = kontext-impl
#let priklad = priklad-impl
#let metodicka-poznamka = metodicka-poznamka-impl
#let interpretace = interpretace-impl
#let shrnuti = shrnuti-impl
#let literatura = literatura-impl

// Stav: Konfigurace bibliografie načtená z `thesis.toml`.
#let bibliography-config = state(
  "unob-bibliography-config",
  (
    "show": true,
    "type": "bib",
    "style": "numeric",
  ),
)

// API: Helpery pro zadání frontmatter přímo v `thesis.typ`.
// Jak: Každý helper vloží neviditelný metadata uzel; `template()` ho načte přes `query`.
#let acknowledgement(content) = [#metadata(content) <unob-fm-acknowledgement>]
#let introduction(content) = [#metadata(content) <unob-fm-introduction>]
#let abstract-cs(content) = [#metadata(content) <unob-fm-abstract-cs>]
#let abstract-en(content) = [#metadata(content) <unob-fm-abstract-en>]
#let keywords-cs(value) = [#metadata(value) <unob-fm-keywords-cs>]
#let keywords-en(value) = [#metadata(value) <unob-fm-keywords-en>]

// Funkce: conclusion
// Co: Vloží lokalizovaný nadpis závěru a obsah kapitoly.
#let conclusion(content) = [
  #heading(level: 1, outlined: true)[#t("conclusion")]
  #content
  #metadata(true) <unob-running-header-end>
]

// Funkce: last-metadata-override
// Účel: Vrátí poslední metadata hodnotu pro zadaný label.
#let last-metadata-override(label) = context {
  let items = query(label)
  if items.len() > 0 { items.last().value } else { none }
}

/* ==========================================
 * 2. Pomocné funkce
 * ========================================== */

// Funkce: get-faculty-color
// Co: Vrátí barvu fakulty podle zkratky.
// Proč: Barva se používá v identitě titulní strany.
// Jak: Pro známé kódy vrací pevné RGB, jinak výchozí `#000000`.
#let get-faculty-color(faculty) = {
  if faculty == "fvl" { rgb("#808205") } else if faculty == "fvt" {
    rgb("#6188cd")
  } else if faculty == "vlf" { rgb("#ea0738") } else if faculty == "uo" {
    rgb("#fec820")
  } else { rgb("#000000") }
}

// Funkce: resolve-theme-color
// Co: Převede hex řetězec z konfigurace na Typst barvu.
// Proč: TOML drží barvy jako text, ale sazba potřebuje `color`.
#let resolve-theme-color(value, fallback: none) = {
  if type(value) == str and value.trim().len() > 0 {
    rgb(value.trim())
  } else {
    fallback
  }
}

// Funkce: get-faculty-name
// Co: Vrátí lokalizovaný název fakulty podle varianty.
// Proč: Stejná data se používají na více místech (cover, prohlášení).
// Jak: Deleguje překlad do `modules/i18n/index.typ`.
#let get-faculty-name(faculty, variant: 1) = {
  context i18n-faculty-name(faculty, variant: variant, lang: text.lang)
}


// Funkce: get-city-name
// Co: Vrátí název města fakulty podle varianty.
// Proč: Potřebné pro lokalizované věty v úvodních stránkách.
// Jak: Deleguje mapování do `modules/i18n/index.typ`.
#let get-city-name(faculty, variant: 1) = {
  context i18n-city-name(faculty, variant: variant, lang: text.lang)
}


// Funkce: get-logo-path
// Co: Sestaví cestu k logu fakulty.
// Proč: `render-cover` očekává jednotnou konvenci názvů loga.
// Jak: Prefix `../../../resources/logos/logo` + kód fakulty velkými písmeny + `.svg`.
#let get-logo-path(faculty) = {
  "../../../resources/logos/logo" + upper(faculty) + ".svg"
}

// Funkce: resolve-glossary-source
// Co: Normalizuje vstupní zdroj glosáře, zkratek a pojmů.
// Proč: API dovoluje bool přepínač i ruční data.
// Jak: `true` načte výchozí TOML, `false|none` vypne, jinak vrátí vstup.
#let resolve-glossary-source(value, default_file) = {
  if value == true {
    read(default_file)
  } else if value == false or value == none {
    false
  } else {
    value
  }
}

// Funkce: has-entries
// Co: Ověří, že hodnota je neprázdný slovník.
// Proč: Prázdné seznamy se nemají propisovat do outline sekcí.
#let has-entries(value) = type(value) == dictionary and value.len() > 0

// Funkce: get-thesis-type-name
// Co: Vrátí lokalizovaný název typu práce pro zadanou variantu.
// Proč: Udržuje jednotné názvosloví napříč dokumentem.
// Jak: Deleguje mapování do `modules/i18n/index.typ`.
#let get-thesis-type-name(thesis_type, variant: 1) = {
  context i18n-thesis-type-name(
    thesis_type,
    variant: variant,
    lang: text.lang,
  )
}

// Funkce: format-name
// Co: Sestaví celé jméno osoby včetně titulů.
// Proč: Sjednocuje tisk jmen na cover/frontmatter stránkách.
// Jak: Přidá `suffix` jen pokud je vyplněný.
#let format-name(person) = [
  #person.prefix
  #person.name
  #if person.suffix != none {
    [#person.surname, #person.suffix]
  } else {
    [#person.surname]
  }
]

// Funkce: format-supervisor-for-declaration
// Co: Vrátí jméno vedoucího nebo školitele ve 2. pádě.
// Proč: Čestné prohlášení je vždy psané česky a vyžaduje správný tvar.
// Jak: Volá `genitiv(...)` pro jméno a příjmení, titul ponechá beze změny.
#let format-supervisor-for-declaration(supervisor) = {
  import "modules/i18n/czech.typ": genitiv
  [
    #supervisor.prefix
    #genitiv(supervisor.name)
    #genitiv(supervisor.surname),
    #if supervisor.suffix != none {
      [#supervisor.suffix,]
    } else {
      []
    }
  ]
}


// Funkce: get-bibliography
// Co: Vrátí bibliografii podle typu zdroje a citačního stylu.
// Proč: Odlišuje lokální CSL pro češtinu a vestavěné styly pro angličtinu.
// Jak: Vybere zdroj (`.yml|.bib`) a styl (`numeric|harvard`) podle `text.lang`.
#let get-bibliography(type: "bib", style: "numeric") = {
  let panic_local = (cs, en) => context {
    if text.lang == "en" { panic(en) } else { panic(cs) }
  }

  // Pravidlo: Vybere soubor se zdroji (`.yml` nebo `.bib`).
  let get_file_path = if type == "yml" {
    "../template/references.yml"
  } else if type == "bib" {
    "../template/references.bib"
  } else {
    panic_local(
      "Nepodporovaný typ souboru! Zvolte: `yml` | `bib`",
      "Unsupported file type! Try: `yml` | `bib`",
    )
  }

  context {
    // Pravidlo: Vybere citační styl podle jazyka dokumentu.
    let citation_style = if text.lang != "en" {
      if style == "numeric" {
        "./csl/numeric.csl"
      } else if style == "harvard" {
        "./csl/harvard.csl"
      } else {
        panic_local(
          "Nepodporovaný citační styl! Zvolte: `numeric` | `harvard`",
          "Unsupported citation style! Try: `numeric` | `harvard`",
        )
      }
    } else {
      if style == "numeric" {
        "iso-690-numeric"
      } else if style == "harvard" {
        "iso-690-author-date"
      } else {
        panic_local(
          "Nepodporovaný citační styl! Zvolte: `numeric` | `harvard`",
          "Unsupported citation style! Try: `numeric` | `harvard`",
        )
      }
    }

    bibliography(
      title: t("bibliography_title"),
      style: citation_style,
      get_file_path,
    )
  }
}

// Funkce: show-bibliography
// Co: Vykreslí bibliografii podle `thesis.toml` (parametry lze přepsat ručně).
#let show-bibliography(kind: auto, style: auto, enabled: auto) = context {
  let cfg_raw = bibliography-config.final()
  let cfg = if type(cfg_raw) == dictionary { cfg_raw } else { (:) }
  let resolved_show = if enabled == auto {
    cfg.at("show", default: true)
  } else {
    enabled
  }

  if resolved_show != true {
    []
  } else {
    let resolved_type = if kind == auto {
      cfg.at("type", default: "bib")
    } else {
      kind
    }
    let resolved_style = if style == auto {
      cfg.at("style", default: "numeric")
    } else {
      style
    }
    get-bibliography(type: resolved_type, style: resolved_style)
  }
}

// Funkce: person
// Co: Vytvoří záznam osoby pro konfiguraci šablony.
// Proč: Zkracuje zápis a drží stejnou datovou strukturu v celém API.
#let person(
  prefix: "",
  name: "",
  surname: "",
  suffix: none,
  sex: none,
) = (
  prefix: prefix,
  name: name,
  surname: surname,
  suffix: suffix,
  sex: sex,
)

// Funkce: format-author-name-for-draft
// Co: Vrátí stručné jméno autora bez titulů pro hlavičku draftu.
// Proč: Draft má mít úvod ve stylu článku bez titulní sazby.
#let format-author-name-for-draft(author, has_value, format_name) = {
  if has_value(author.name) and has_value(author.surname) {
    [#author.name #author.surname]
  } else if has_value(author.name) {
    [#author.name]
  } else if has_value(author.surname) {
    [#author.surname]
  } else {
    format_name(author)
  }
}

// Funkce: render-draft-header
// Co: Vykreslí minimalistickou hlavičku draftu (název, autor, banner).
// Proč: V draft režimu nemá být titulní strana ani fakultní bloky.
#let render-draft-header(thesis, author, has_value, format_name, get_thesis_type_name) = context {
  set par(first-line-indent: 0mm)
  set align(center)

  text(size: 18pt, weight: "bold")[#thesis.title]
  parbreak()

  format-author-name-for-draft(author, has_value, format_name)
  parbreak()

  let draft_banner = if text.lang == "en" {
    [DRAFT #upper(get_thesis_type_name(thesis.type, variant: 1))]
  } else {
    [DRAFT #upper(get_thesis_type_name(thesis.type, variant: 2))]
  }
  text(size: 11pt, style: "italic")[#draft_banner]

  v(1.2em)
  set align(left)
}

// Funkce: render-draft-abstracts
// Co: Vykreslí jen vyplněné abstrakty a klíčová slova.
// Proč: Draft nemá obsahovat výchozí zástupné texty.
#let render-draft-abstracts(abstract, keywords, has_value) = context {
  let has_cs_abstract = has_value(abstract.czech)
  let has_en_abstract = has_value(abstract.english)
  let has_cs_keywords = has_value(keywords.czech)
  let has_en_keywords = has_value(keywords.english)
  let has_cs_block = has_cs_abstract or has_cs_keywords
  let has_en_block = has_en_abstract or has_en_keywords

  if has_cs_block or has_en_block {
    grid(
      columns: (1fr, 1fr),
      column-gutter: 8mm,
      row-gutter: 0mm,
      [
        #if has_cs_block {
          block(width: 100%)[
            #set align(center)
            #heading(numbering: none, outlined: false, bookmarked: false, level: 1)[ABSTRAKT]
            #if has_cs_abstract {
              abstract.czech
            }
            #if has_cs_keywords {
              if has_cs_abstract {
                parbreak()
              }
              [*Klíčová slova:* #keywords.czech]
            }
          ]
        }
      ],
      [
        #if has_en_block {
          block(width: 100%)[
            #set align(center)
            #heading(numbering: none, outlined: false, bookmarked: false, level: 1)[ABSTRACT]
            #if has_en_abstract {
              abstract.english
            }
            #if has_en_keywords {
              if has_en_abstract {
                parbreak()
              }
              [*Keywords:* #keywords.english]
            }
          ]
        }
      ],
    )
    parbreak()
  }
}

/* ==========================================
 * 3. Hlavní funkce Template
 * ========================================== */

// Poznámka: Blok `///` níže slouží pro generování dokumentace přes `tidy`.

/// Funkce: template
/// Co: Hlavní vstupní API pro sazbu celé práce.
/// Proč: Drží skládání dokumentu na jednom místě a zajišťuje konzistentní výstup.
/// Jak:
/// - Normalizuje vstupy (zkratky, pojmy, osoby, režim).
/// - Provede validaci konfigurace.
/// - Aplikuje globální styly a vykreslí cover/frontmatter/seznamy/tělo.
/// - Vkládá pouze ty oddíly, které jsou povolené a mají data.
///
/// Doporučený postup při předání projektu:
/// 1. Udržuj všechna metadata v `#show: template.with(...)`.
/// 2. Slovník drž primárně v `template/glossary.toml` (`acronyms: true`, `terms: true`).
/// 3. Pro rychlý náhled používej `draft: true`, pro finální export `draft: false`.
///
/// Minimální příklad:
/// ```typ
/// #set text(lang: "cs")
/// #show: template.with(
///   university: (faculty: "fvl"),
///   thesis: (type: "master", title: [Název práce]),
///   author: person(name: "Jan", surname: "Novák", sex: "M"),
///   supervisor: person(name: "Jana", surname: "Nováková", sex: "F"),
/// )
/// ```
#let template(
  /// Co: Identita školy pro titulní stranu a prohlášení.
  /// Proč: Fakulta/obor určují hlavičky a lokalizované texty.
  /// Jak: `faculty` je `fvl|fvt|vlf|uo`, program a specializace jsou volitelné.
  university: (
    faculty: "uo",
    programme: "",
    specialisation: "",
  ),
  /// Co: Metadata práce.
  /// Proč: Ovlivňují titulní stranu, čestné prohlášení a další lokální texty.
  /// Jak: `type` podporuje `bachelor|master|doctoral`.
  thesis: (
    type: "",
    title: "",
  ),
  /// Co: Autor práce.
  /// Proč: Používá se na cover i ve frontmatter částech.
  /// Jak: Formát `person(...)` (`prefix`, `name`, `surname`, `suffix`, `sex`).
  author: (
    prefix: "",
    name: "",
    surname: "",
    suffix: "",
    sex: "",
  ),
  /// Co: Vedoucí nebo školitel práce.
  /// Jak: Stejná struktura jako `author`.
  supervisor: (
    prefix: "",
    name: "",
    surname: "",
    suffix: "",
    sex: "",
  ),
  /// Co: Odborný konzultant nebo školitel-specialista.
  /// Jak: Stejná struktura jako `author`.
  first_advisor: (
    prefix: "",
    name: "",
    surname: "",
    suffix: "",
    sex: "",
  ),
  /// Co: Druhý školitel-specialista.
  /// Jak: Stejná struktura jako `author`.
  second_advisor: (
    prefix: "",
    name: "",
    surname: "",
    suffix: "",
    sex: "",
  ),
  /// Co: Přepínače čestného prohlášení.
  /// Proč: Některé fakulty vyžadují deklaraci AI zvlášť.
  /// Jak: `declaration` a `ai_used` jsou booleany.
  declaration: (
    declaration: true,
    ai_used: false,
  ),
  /// Co: Vložení skenu zadání (PNG).
  /// Proč: Umožní mít oficiální zadání přímo v PDF práce.
  /// Jak: `front/back` jsou booleany; při `true` se očekává `front.png`/`back.png`.
  assignment: (
    front: true,
    back: true,
  ),
  /// Co: Volitelný blok poděkování.
  /// Jak: `false|none` blok vypne, content blok zobrazí.
  acknowledgement: false,
  /// Co: Přepínače generovaných seznamů.
  /// Proč: Každá práce může mít jinou požadovanou strukturu.
  /// Jak: Všechny položky jsou bool (`headings`, `acronyms`, `terms`, ...).
  outlines: (
    headings: true,
    acronyms: false,
    terms: false,
    figures: false,
    tables: false,
    equations: false,
    listings: false,
  ),
  /// Co: Zdroj zkratek.
  /// Proč: Umožňuje jeden společný TOML i ruční data.
  /// Jak: `true` načte `template/glossary.toml`, `false` vypne, jinak použije vstup.
  acronyms: false,
  /// Co: Zdroj pojmů (glosáře).
  /// Proč: Pojmy mohou sdílet stejný TOML se zkratkami.
  /// Jak: Stejná pravidla jako u `acronyms`.
  terms: false,
  /// Co: Abstrakty práce.
  /// Jak: `czech` a `english` jsou content bloky.
  abstract: (
    czech: [],
    english: [],
  ),
  /// Co: Klíčová slova.
  /// Jak: Stringy oddělené čárkou (`czech`, `english`).
  keywords: (
    czech: "",
    english: "",
  ),
  /// Co: Volitelný theme override pro barvy.
  /// Jak: `color: true` zapne barvy globálně; `notes-colored`, `links-colored`, `faculty-colored`
  ///      umožní granulární vypnutí. `link_color` je absolutní override pro barvu odkazů.
  theme: (
    color:           false,
    notes_colored:   true,
    links_colored:   true,
    faculty_colored: true,
    faculty_color:   none,
    link_color:      none,
  ),
  /// Co: Volitelný úvod před tělem práce.
  /// Jak: Content; prázdný `[]` nic nevloží.
  introduction: [],
  /// Co: Přepínač draft režimu.
  /// Proč: Odděluje rychlý náhled od plné sazby.
  /// Jak: `true` = draft, `false` = plná sazba.
  draft: false,
  /// Co: Zapnutí stručného guide modulu.
  /// Jak: Bool; aktivní jen při `draft: false`.
  guide: true,
  /// Co: Zapnutí rozšířené interní dokumentace.
  /// Jak: Bool; aktivní jen při `draft: false`.
  docs: false,
  /// Co: Přísná kontrola před odevzdáním.
  /// Jak: `true` aktivuje povinné kontroly abstraktu, klíčových slov a úvodu.
  submit_check: false,
  body,
) = {
  let normalized_thesis = (
    type: i18n-normalize-thesis-type(thesis.type),
    title: thesis.title,
  )

  let unified_requested = acronyms == true or terms == true
  let unified_source = if unified_requested {
    resolve-glossary-source(true, "../template/glossary.toml")
  } else {
    false
  }
  let unified_entries = normalize-glossary-input(unified_source)

  let resolved_acronyms = if acronyms == true {
    glossary-to-acronyms(unified_entries)
  } else {
    let acronyms_source = resolve-glossary-source(acronyms, "../template/acronyms.toml")
    normalize-acronyms-input(acronyms_source)
  }

  let resolved_terms = if terms == true {
    glossary-to-terms(unified_entries)
  } else {
    let terms_source = resolve-glossary-source(terms, "../template/terms.toml")
    normalize-terms-input(terms_source)
  }

  let effective_outlines = (
    headings: outlines.headings,
    acronyms: if has-entries(resolved_acronyms) { outlines.acronyms } else { false },
    terms: if has-entries(resolved_terms) { outlines.terms } else { false },
    figures: outlines.figures,
    tables: outlines.tables,
    equations: outlines.equations,
    listings: outlines.listings,
  )

  let override_acknowledgement = last-metadata-override(<unob-fm-acknowledgement>)
  let override_introduction = last-metadata-override(<unob-fm-introduction>)
  let override_abstract_cs = last-metadata-override(<unob-fm-abstract-cs>)
  let override_abstract_en = last-metadata-override(<unob-fm-abstract-en>)
  let override_keywords_cs = last-metadata-override(<unob-fm-keywords-cs>)
  let override_keywords_en = last-metadata-override(<unob-fm-keywords-en>)

  let effective_acknowledgement = coalesce(override_acknowledgement, acknowledgement)
  let effective_introduction = coalesce(override_introduction, introduction)
  let effective_abstract = (
    czech: coalesce(override_abstract_cs, abstract.czech),
    english: coalesce(override_abstract_en, abstract.english),
  )
  let effective_keywords = (
    czech: coalesce(override_keywords_cs, keywords.czech),
    english: coalesce(override_keywords_en, keywords.english),
  )
  let effective_theme = (
    color:           theme.color == true,
    notes_colored:   theme.color == true and theme.at("notes_colored",   default: true) != false,
    links_colored:   theme.color == true and theme.at("links_colored",   default: true) != false,
    faculty_colored: theme.color == true and theme.at("faculty_colored", default: true) != false,
    faculty_color:   resolve-theme-color(theme.faculty_color, fallback: get-faculty-color(university.faculty)),
    link_color:      resolve-theme-color(theme.link_color, fallback: none),
  )

  validate-glossary-registry(resolved_acronyms, resolved_terms)

  validate-config(
    draft,
    university,
    thesis,
    author,
    supervisor,
    declaration,
    assignment,
    effective_outlines,
    resolved_acronyms,
    resolved_terms,
    guide,
    docs,
    submit_check,
  )

  validate-submit-check(
    submit_check,
    draft,
    supervisor,
    effective_abstract,
    effective_keywords,
    effective_introduction,
  )

  show: apply-base-styles.with(
    draft: draft,
    author: author,
    thesis: normalized_thesis,
    abstract: effective_abstract,
    keywords: effective_keywords,
    theme: effective_theme,
  )
  show: apply-heading-styles.with(draft: draft)
  show: apply-figure-styles
  show: glossary-show
  // Pravidlo: Značka režimu pro `annex` při uživatelském `#show: annex`.
  [#metadata(draft) <unob-layout-draft>]
  // Pravidlo: Inicializuje registry zkratek a pojmů pro aktuální dokument.
  init-glossary-runtime(resolved_acronyms, terms: resolved_terms)
  // Pravidlo: Nastaví barevný/B&W režim pro callout poznámky.
  setup-notes-color-impl(effective_theme.notes_colored)

  if draft {
    setup-draft-todos()
    set page(
      numbering: "1",
      footer: context {
        set align(center)
        counter(page).display(page.numbering)
      },
    )
    render-draft-header(
      normalized_thesis,
      author,
      has-value,
      format-name,
      get-thesis-type-name,
    )
    render-draft-abstracts(effective_abstract, effective_keywords, has-value)
    body
  } else {
    let show_manual = docs != false
    if show_manual {
      include "docs.typ"
    }

    if guide != false {
      include "modules/guide.typ"
    }

    render-cover(
      university,
      normalized_thesis,
      author,
      supervisor,
      first_advisor,
      second_advisor,
      has-value,
      has-person,
      format-name,
      get-faculty-name,
      get-logo-path,
      get-thesis-type-name,
      get-city-name,
    )

    render-assignment(assignment)
    render-acknowledgement(effective_acknowledgement, has-value)
    render-declaration(
      declaration,
      author,
      supervisor,
      university,
      normalized_thesis,
      format-supervisor-for-declaration,
      format-name,
      get-thesis-type-name,
      get-faculty-name,
      get-city-name,
    )
    render-abstracts(effective_abstract, effective_keywords)
    set page(footer: context {
      set align(center)
      counter(page).display("1")
    })
    render-lists(
      effective_outlines,
      resolved_acronyms,
      resolved_terms,
      has-used-acronyms,
      has-used-terms,
      generate-acronyms-list,
      generate-terms-list,
    )
    render-introduction(effective_introduction)

    body
  }
}

// Funkce: thesis-with
// Účel: Krátký wrapper nad `template` s nejčastějším nastavením.
#let thesis-with(
  body,
  lang: "cs",
  draft: false,
  faculty: "uo",
  programme: [],
  specialisation: [],
  thesis: (
    type: "bachelor",
    title: [Název práce],
  ),
  author: person(name: "Jan", surname: "Novák", sex: "M"),
  supervisor: person(name: "Jana", surname: "Nováková", sex: "F"),
  first_advisor: person(),
  second_advisor: person(),
  assignment: false,
  acknowledgement: false,
  declaration: true,
  ai_used: false,
  acronyms: false,
  terms: false,
  abstract: (
    czech: [],
    english: [],
  ),
  keywords: (
    czech: "",
    english: "",
  ),
  theme: (
    color:           false,
    notes_colored:   true,
    links_colored:   true,
    faculty_colored: true,
    faculty_color:   none,
    link_color:      none,
  ),
  introduction: [],
  outlines: (
    headings: true,
    acronyms: false,
    terms: false,
    figures: true,
    tables: true,
    equations: false,
    listings: false,
  ),
  guide: false,
  docs: false,
  submit_check: false,
) = {
  set text(lang: lang)
  show: template.with(
    draft: draft,
    university: (
      faculty: faculty,
      programme: programme,
      specialisation: specialisation,
    ),
    thesis: thesis,
    author: author,
    supervisor: supervisor,
    first_advisor: first_advisor,
    second_advisor: second_advisor,
    assignment: (
      front: assignment,
      back: assignment,
    ),
    acknowledgement: acknowledgement,
    abstract: abstract,
    keywords: keywords,
    theme: theme,
    declaration: (
      declaration: declaration,
      ai_used: ai_used,
    ),
    acronyms: acronyms,
    terms: terms,
    outlines: outlines,
    introduction: introduction,
    guide: guide,
    docs: docs,
    submit_check: submit_check,
  )
  body
}

// Funkce: thesis
// Účel: Zjednodušený vstup šablony přes konfigurační TOML soubor.
// Jak: Načte TOML, předá parsování modulu `config.typ` a aplikuje vrácené `show`.
#let thesis(body, file: "../template/thesis.toml") = {
  let resolved_file = if type(file) == str and file.starts-with("./") {
    "../template/" + file.slice(2)
  } else {
    file
  }
  let cfg = toml(bytes(read(resolved_file)))
  let resolved = load-thesis-from-toml(cfg, thesis-with)

  show: resolved.at("show")
  bibliography-config.update(resolved.at("bibliography"))
  body
}
