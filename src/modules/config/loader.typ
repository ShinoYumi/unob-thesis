/*
Modul: src/modules/config.typ
Co: Loader konfigurace z `thesis.toml`.
Proč: Odděluje parsování/validaci TOML od hlavní orchestrace v `lib.typ`.
Jak: Přijme již načtené TOML, ověří strukturu a vrátí `show` pravidlo a nastavení bibliografie.
*/

// Funkce: msg
// Účel: Vrátí lokalizovanou zprávu podle `lang`.
#let msg(lang, cs, en) = if lang == "en" { en } else { cs }

// Funkce: has-key
// Účel: Ověří, že klíč ve slovníku existuje.
#let has-key(dict, key) = {
  type(dict) == dictionary and dict.at(key, default: none) != none
}

// Funkce: detect-lang
// Účel: Určí jazyk chyb ještě před plnou validací konfigurace.
#let detect-lang(cfg) = {
  if type(cfg) == dictionary and type(cfg.at("lang", default: none)) == str {
    if lower(cfg.at("lang")) == "en" { "en" } else { "cs" }
  } else {
    "cs"
  }
}

// Funkce: panic-expected
// Účel: Vyvolá chybu při neplatném typu hodnoty.
#let panic-expected(lang, path, expected, value) = {
  let got = str(type(value))
  panic(msg(
    lang,
    "Neplatný typ v `thesis.toml` pro `" + path + "`. Očekáváno: " + expected + ", nalezeno: " + got + ".",
    "Invalid type in `thesis.toml` for `" + path + "`. Expected: " + expected + ", got: " + got + ".",
  ))
}

// Funkce: panic-enum
// Účel: Vyvolá chybu při nepodporované hodnotě.
#let panic-enum(lang, path, allowed, value) = {
  let options = allowed.join(" | ")
  panic(msg(
    lang,
    "Nepodporovaná hodnota v `thesis.toml` pro `" + path + "`: `" + str(value)
      + "`. Povolené: `" + options + "`.",
    "Unsupported value in `thesis.toml` for `" + path + "`: `" + str(value)
      + "`. Allowed: `" + options + "`.",
  ))
}

// Data: Mapování historických klíčů na aktuální.
#let _legacy_hints = (
  "root/flags": "lists",
  "root/programme": "program",
  "root/specialisation": "specialization",
  "root/first_advisor": "advisor",
  "root/second_advisor": "co_supervisor",
  "lists/submit-check": "submit_check",
  "bibliography/type": "source",
  "bibliography/style": "citation_style",
  "bibliography/show": "lists.bibliography",
)

// Funkce: legacy-hint
// Účel: Vrátí doporučený klíč pro historický zápis.
#let legacy-hint(path, key) = _legacy_hints.at(path + "/" + key, default: none)

// Funkce: panic-unknown-key
// Účel: Vyvolá chybu pro neznámý nebo historický klíč.
#let panic-unknown-key(lang, path, key) = {
  let full_path = if path == "root" { key } else { path + "." + key }
  let hint = legacy-hint(path, key)
  if hint != none {
    panic(msg(
      lang,
      "Nepodporovaný (legacy) klíč v `thesis.toml`: `" + full_path + "`. Použijte `" + hint + "`.",
      "Unsupported legacy key in `thesis.toml`: `" + full_path + "`. Use `" + hint + "`.",
    ))
  } else {
    panic(msg(
      lang,
      "Neznámý klíč v `thesis.toml`: `" + full_path + "`.",
      "Unknown key in `thesis.toml`: `" + full_path + "`.",
    ))
  }
}

// Funkce: validate-known-keys
// Účel: Ověří, že tabulka obsahuje jen podporované klíče.
#let validate-known-keys(dict, allowed, path, lang) = {
  if type(dict) != dictionary {
    panic-expected(lang, path, "table", dict)
  }
  for key in dict.keys() {
    let known = allowed.any(item => item == key)
    if not known {
      panic-unknown-key(lang, path, key)
    }
  }
}

// Funkce: read-table
// Účel: Načte volitelnou TOML tabulku a ověří její typ.
#let read-table(dict, key, lang, path: auto) = {
  let key_path = if path == auto { key } else { path }
  if not has-key(dict, key) {
    (:)
  } else {
    let value = dict.at(key)
    if type(value) != dictionary {
      panic-expected(lang, key_path, "table", value)
    }
    value
  }
}

// Funkce: read-str
// Účel: Načte textový řetězec z TOML.
#let read-str(dict, key, default: "", lang: "cs", path: auto) = {
  let key_path = if path == auto { key } else { path }
  if not has-key(dict, key) {
    default
  } else {
    let value = dict.at(key)
    if type(value) != str {
      panic-expected(lang, key_path, "string", value)
    }
    value
  }
}

// Funkce: read-bool
// Účel: Načte bool hodnotu z TOML.
#let read-bool(dict, key, default: false, lang: "cs", path: auto) = {
  let key_path = if path == auto { key } else { path }
  if not has-key(dict, key) {
    default
  } else {
    let value = dict.at(key)
    if type(value) != bool {
      panic-expected(lang, key_path, "bool", value)
    }
    value
  }
}

// Funkce: read-enum-str
// Účel: Načte text a ověří, že je v povoleném seznamu.
#let read-enum-str(dict, key, allowed, default: none, lang: "cs", path: auto) = {
  let key_path = if path == auto { key } else { path }
  if not has-key(dict, key) {
    default
  } else {
    let value = read-str(dict, key, lang: lang, path: key_path)
    if not allowed.any(item => item == value) {
      panic-enum(lang, key_path, allowed, value)
    }
    value
  }
}

// Funkce: suffix-or-none
// Účel: Normalizuje prázdný suffix na `none`.
#let suffix-or-none(value) = {
  if value.trim().len() == 0 { none } else { value }
}

// Funkce: _read_section
// Účel: Načte homogenní sekci TOML dle schématu do slovníku.
// Schema: pole tuplů (key, kind, default) kde kind je "bool" | "str" | "enum".
// Pro "enum" je čtvrtý prvek tuple seznam povolených hodnot.
#let _read_section(dict, schema, section, lang) = {
  let result = (:)
  for entry in schema {
    let key = entry.at(0)
    let kind = entry.at(1)
    let default_val = entry.at(2)
    let path = section + "." + key
    result.insert(key, if kind == "bool" {
      read-bool(dict, key, default: default_val, lang: lang, path: path)
    } else if kind == "enum" {
      read-enum-str(dict, key, entry.at(3), default: default_val, lang: lang, path: path)
    } else {
      read-str(dict, key, default: default_val, lang: lang, path: path)
    })
  }
  result
}

// Funkce: person-from-cfg
// Účel: Načte osobu z tabulky a ověří všechny podporované klíče.
#let person-from-cfg(raw, path, lang, default_sex: none) = {
  validate-known-keys(
    raw,
    ("prefix", "name", "surname", "suffix", "sex"),
    path,
    lang,
  )
  let prefix = read-str(raw, "prefix", default: "", lang: lang, path: path + ".prefix")
  let name = read-str(raw, "name", default: "", lang: lang, path: path + ".name")
  let surname = read-str(raw, "surname", default: "", lang: lang, path: path + ".surname")
  let suffix = read-str(raw, "suffix", default: "", lang: lang, path: path + ".suffix")
  let sex = read-enum-str(
    raw,
    "sex",
    ("M", "F"),
    default: default_sex,
    lang: lang,
    path: path + ".sex",
  )

  (
    prefix: prefix,
    name: name,
    surname: surname,
    suffix: suffix-or-none(suffix),
    sex: sex,
  )
}

// Funkce: acknowledgement-from-cfg
// Účel: Převede bool přepínač poděkování na hodnotu pro šablonu.
#let acknowledgement-from-cfg(value) = if value { [] } else { false }

// Funkce: load-thesis-from-toml
// Účel: Převede validovaný TOML na `show` pravidlo a bibliografickou konfiguraci.
#let load-thesis-from-toml(cfg, thesis_with_fn) = {
  let detected_lang = detect-lang(cfg)
  validate-known-keys(
    cfg,
    (
      "lang",
      "draft",
      "faculty",
      "program",
      "specialization",
      "thesis",
      "author",
      "supervisor",
      "advisor",
      "co_supervisor",
      "lists",
      "outlines",
      "bibliography",
      "theme",
    ),
    "root",
    detected_lang,
  )

  let lang_cfg = read-enum-str(
    cfg,
    "lang",
    ("cs", "en"),
    default: "cs",
    lang: detected_lang,
    path: "lang",
  )
  let thesis_cfg = read-table(cfg, "thesis", lang_cfg, path: "thesis")
  let lists_cfg = read-table(cfg, "lists", lang_cfg, path: "lists")
  let outlines_cfg = read-table(cfg, "outlines", lang_cfg, path: "outlines")
  let bibliography_cfg = read-table(
    cfg,
    "bibliography",
    lang_cfg,
    path: "bibliography",
  )
  let theme_cfg = read-table(cfg, "theme", lang_cfg, path: "theme")
  let author_cfg = read-table(cfg, "author", lang_cfg, path: "author")
  let supervisor_cfg = read-table(cfg, "supervisor", lang_cfg, path: "supervisor")
  let advisor_cfg = read-table(cfg, "advisor", lang_cfg, path: "advisor")
  let co_supervisor_cfg = read-table(
    cfg,
    "co_supervisor",
    lang_cfg,
    path: "co_supervisor",
  )

  validate-known-keys(thesis_cfg, ("type", "title"), "thesis", lang_cfg)
  validate-known-keys(
    lists_cfg,
    (
      "assignment",
      "acknowledgement",
      "declaration",
      "ai_used",
      "acronyms",
      "terms",
      "guide",
      "docs",
      "bibliography",
      "submit_check",
    ),
    "lists",
    lang_cfg,
  )
  validate-known-keys(
    outlines_cfg,
    (
      "headings",
      "acronyms",
      "terms",
      "figures",
      "tables",
      "equations",
      "listings",
    ),
    "outlines",
    lang_cfg,
  )
  validate-known-keys(
    bibliography_cfg,
    ("source", "citation_style"),
    "bibliography",
    lang_cfg,
  )
  validate-known-keys(
    theme_cfg,
    ("color", "notes_colored", "links_colored", "faculty_colored", "faculty_color", "link_color"),
    "theme",
    lang_cfg,
  )

  let program_cfg = read-str(
    cfg,
    "program",
    default: "",
    lang: lang_cfg,
    path: "program",
  )
  let specialization_cfg = read-str(
    cfg,
    "specialization",
    default: "",
    lang: lang_cfg,
    path: "specialization",
  )
  let draft_cfg = read-bool(
    cfg,
    "draft",
    default: false,
    lang: lang_cfg,
    path: "draft",
  )
  let faculty_cfg = read-enum-str(
    cfg,
    "faculty",
    ("fvl", "fvt", "vlf", "uo"),
    default: "uo",
    lang: lang_cfg,
    path: "faculty",
  )
  let thesis_type_cfg = read-enum-str(
    thesis_cfg,
    "type",
    ("bachelor", "master", "doctoral"),
    default: "bachelor",
    lang: lang_cfg,
    path: "thesis.type",
  )
  let thesis_title_cfg = read-str(
    thesis_cfg,
    "title",
    default: "Název práce",
    lang: lang_cfg,
    path: "thesis.title",
  )
  let lists_r = _read_section(lists_cfg, (
    ("assignment",      "bool", false),
    ("acknowledgement", "bool", false),
    ("declaration",     "bool", true),
    ("ai_used",         "bool", false),
    ("acronyms",        "bool", true),
    ("terms",           "bool", true),
    ("guide",           "bool", false),
    ("docs",            "bool", false),
    ("bibliography",    "bool", true),
    ("submit_check",    "bool", false),
  ), "lists", lang_cfg)

  let outlines_r = _read_section(outlines_cfg, (
    ("headings",  "bool", true),
    ("acronyms",  "bool", true),
    ("terms",     "bool", true),
    ("figures",   "bool", true),
    ("tables",    "bool", true),
    ("equations", "bool", false),
    ("listings",  "bool", false),
  ), "outlines", lang_cfg)
  let bibliography_source_cfg = read-enum-str(
    bibliography_cfg,
    "source",
    ("bib", "yml"),
    default: "bib",
    lang: lang_cfg,
    path: "bibliography.source",
  )
  let bibliography_style_cfg = read-enum-str(
    bibliography_cfg,
    "citation_style",
    ("numeric", "harvard"),
    default: "numeric",
    lang: lang_cfg,
    path: "bibliography.citation_style",
  )
  let theme_color_cfg = read-bool(
    theme_cfg,
    "color",
    default: false,
    lang: lang_cfg,
    path: "theme.color",
  )
  let theme_notes_colored_cfg   = read-bool(theme_cfg, "notes_colored",   default: true, lang: lang_cfg, path: "theme.notes_colored")
  let theme_links_colored_cfg   = read-bool(theme_cfg, "links_colored",   default: true, lang: lang_cfg, path: "theme.links_colored")
  let theme_faculty_colored_cfg = read-bool(theme_cfg, "faculty_colored", default: true, lang: lang_cfg, path: "theme.faculty_colored")
  let theme_faculty_color_cfg = suffix-or-none(read-str(
    theme_cfg,
    "faculty_color",
    default: "",
    lang: lang_cfg,
    path: "theme.faculty_color",
  ))
  let theme_link_color_cfg = suffix-or-none(read-str(
    theme_cfg,
    "link_color",
    default: "",
    lang: lang_cfg,
    path: "theme.link_color",
  ))

  let resolved_bibliography_cfg = (
    "show": lists_r.at("bibliography"),
    "type": bibliography_source_cfg,
    "style": bibliography_style_cfg,
  )

  let show_rule = thesis_with_fn.with(
    lang: lang_cfg,
    draft: draft_cfg,
    faculty: faculty_cfg,
    programme: program_cfg,
    specialisation: specialization_cfg,
    thesis: (
      type: thesis_type_cfg,
      title: thesis_title_cfg,
    ),
    author: person-from-cfg(author_cfg, "author", lang_cfg, default_sex: "M"),
    supervisor: person-from-cfg(
      supervisor_cfg,
      "supervisor",
      lang_cfg,
      default_sex: "F",
    ),
    first_advisor: person-from-cfg(advisor_cfg, "advisor", lang_cfg),
    second_advisor: person-from-cfg(
      co_supervisor_cfg,
      "co_supervisor",
      lang_cfg,
    ),
    assignment: lists_r.at("assignment"),
    acknowledgement: acknowledgement-from-cfg(lists_r.at("acknowledgement")),
    declaration: lists_r.at("declaration"),
    ai_used: lists_r.at("ai_used"),
    acronyms: lists_r.at("acronyms"),
    terms: lists_r.at("terms"),
    abstract: (
      czech: [],
      english: [],
    ),
    keywords: (
      czech: "",
      english: "",
    ),
    outlines: (
      headings: outlines_r.at("headings"),
      acronyms: outlines_r.at("acronyms"),
      terms: outlines_r.at("terms"),
      figures: outlines_r.at("figures"),
      tables: outlines_r.at("tables"),
      equations: outlines_r.at("equations"),
      listings: outlines_r.at("listings"),
    ),
    theme: (
      color:           theme_color_cfg,
      notes_colored:   theme_notes_colored_cfg,
      links_colored:   theme_links_colored_cfg,
      faculty_colored: theme_faculty_colored_cfg,
      faculty_color:   theme_faculty_color_cfg,
      link_color:      theme_link_color_cfg,
    ),
    guide: lists_r.at("guide"),
    docs: lists_r.at("docs"),
    submit_check: lists_r.at("submit_check"),
    introduction: [],
  )

  (
    "show": show_rule,
    "bibliography": resolved_bibliography_cfg,
  )
}
