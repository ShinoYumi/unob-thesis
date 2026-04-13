#import "../vendor/glossarium/glossarium.typ": make-glossary, register-glossary, print-glossary, count-refs, gls, glspl
#import "../vendor/glossarium/themes/default.typ": is-first

#let acronyms-group = "__acronyms"
#let terms-group = "__terms"
#let acronym-label-prefix = "__unob_acronym_list_"

// API: Veřejné helpery nad balíčkem glossarium.
#let glossary-show = make-glossary

// API: Konstanty stylů pro `trm(...)`.
#let singular = "singular"
#let plural = "plural"
#let first = "first"
#let first-plural = "first_plural"

// Stav: Sdílené registry zkratek a pojmů.
#let acronyms-registry = state("unob-acronyms-registry", (:))
#let terms-registry = state("unob-terms-registry", (:))

// Funkce: panic-local
// Účel: Vyvolá chybu v jazyce dokumentu (`cs` / `en`).
#let panic-local(cs, en) = context {
  if text.lang == "en" { panic(en) } else { panic(cs) }
}

// Funkce: key-has-disallowed-chars
// Účel: Ověří, že klíč neobsahuje znaky, které komplikují vyhledávání.
#let key-has-disallowed-chars(key) = {
  (
    key.contains(" ")
      or key.contains(".")
      or key.contains("/")
      or key.contains("\\")
      or key.contains(":")
      or key.contains(";")
      or key.contains(",")
      or key.contains("\"")
      or key.contains("'")
      or key.contains("(")
      or key.contains(")")
      or key.contains("[")
      or key.contains("]")
      or key.contains("{")
      or key.contains("}")
      or key.contains("\t")
      or key.contains("\n")
  )
}

// Funkce: validate-case-insensitive-keys
// Účel: Ověří kolize klíčů při porovnání bez ohledu na velikost písmen.
#let validate-case-insensitive-keys(label_cs, label_en, definitions) = {
  let index = (:)
  for (raw_key, _) in definitions.pairs() {
    let key = str(raw_key).trim()
    if key.len() == 0 {
      panic-local(
        "Klíč v `" + label_cs + "` nesmí být prázdný.",
        "Key in `" + label_en + "` must not be empty.",
      )
    }
    if key-has-disallowed-chars(key) {
      panic-local(
        "Klíč `" + key + "` v `" + label_cs
          + "` obsahuje nepovolené znaky. Použijte písmena/čísla/`_`/`-`.",
        "Key `" + key + "` in `" + label_en
          + "` contains unsupported characters. Use letters/digits/`_`/`-`.",
      )
    }

    let lookup = lower(key)
    let existing = index.at(lookup, default: ())
    index.insert(lookup, existing + (key,))
  }

  for (lookup, collisions) in index.pairs() {
    if collisions.len() > 1 {
      panic-local(
        "Kolize klíčů v `" + label_cs + "` (case-insensitive): "
          + collisions.join(", "),
        "Case-insensitive key collision in `" + label_en + "`: "
          + collisions.join(", "),
      )
    }
  }
}

// Funkce: validate-short-duplicates
// Účel: Ověří duplicitní hodnoty `short` mezi zkratkami a pojmy.
#let validate-short-duplicates(acronyms, terms) = {
  let short_index = (:)

  for (raw_key, value) in acronyms.pairs() {
    let key = str(raw_key)
    let short_value = if type(value) == dictionary {
      value.at("short", default: value.at("abbr", default: key))
    } else {
      key
    }
    let short = lower(str(short_value))
    let owner = "acronyms:" + key
    let existing = short_index.at(short, default: ())
    short_index.insert(short, existing + (owner,))
  }

  for (raw_key, value) in terms.pairs() {
    let key = str(raw_key)
    let short = if type(value) == dictionary {
      lower(str(value.at("short", default: key)))
    } else {
      lower(key)
    }
    let owner = "terms:" + key
    let existing = short_index.at(short, default: ())
    short_index.insert(short, existing + (owner,))
  }

  for (short, owners) in short_index.pairs() {
    if owners.len() > 1 {
      let source_keys = owners
        .map(owner => {
          let parts = owner.split(":")
          if parts.len() > 1 { parts.at(1) } else { owner }
        })
      let unique_sources = source_keys.dedup()

      // Pravidlo: Stejný `short` je povolen, pokud jde o tentýž zdrojový klíč
      // napříč reprezentací jedné položky jako zkratky i pojmu.
      if unique_sources.len() > 1 {
        panic-local(
          "Duplicitní `short` `" + short + "`: " + owners.join(", "),
          "Duplicate `short` `" + short + "`: " + owners.join(", "),
        )
      }
    }
  }
}

// Funkce: validate-glossary-registry
// Účel: Ověří integritu registru zkratek a pojmů před sazbou.
#let validate-glossary-registry(acronyms, terms) = {
  let safe_acronyms = if type(acronyms) == dictionary { acronyms } else { (:) }
  let safe_terms = if type(terms) == dictionary { terms } else { (:) }

  validate-case-insensitive-keys("zkratky", "acronyms", safe_acronyms)
  validate-case-insensitive-keys("pojmy", "terms", safe_terms)
  validate-short-duplicates(safe_acronyms, safe_terms)
}

// Funkce: normalize-acronyms-value
// Účel: Normalizuje jednu položku zkratky do interního tvaru.
#let normalize-acronyms-value(value) = {
  if type(value) == str {
    value
  } else if type(value) == array {
    if value.len() == 1 {
      value.at(0)
    } else if value.len() == 2 {
      (value.at(0), value.at(1))
    } else {
      panic-local(
        "Pole zkratky musí mít 1 nebo 2 položky.",
        "Acronym array must have 1 or 2 items.",
      )
    }
  } else if type(value) == dictionary {
    let en = value.at("en", default: value.at("english", default: none))
    let cs = value.at("cs", default: value.at("czech", default: none))
    let text_value = value.at("value", default: value.at("text", default: none))
    let short = value.at("short", default: value.at("abbr", default: none))
    let plural_form = value.at("plural", default: none)
    let longplural = value.at("longplural", default: value.at("en_plural", default: none))
    let csplural = value.at("csplural", default: value.at("cs_plural", default: none))

    if en != none and cs != none {
      (
        short: short,
        en: en,
        cs: cs,
        plural: plural_form,
        longplural: longplural,
        csplural: csplural,
      )
    } else if en != none {
      (
        short: short,
        en: en,
        cs: none,
        plural: plural_form,
        longplural: longplural,
        csplural: csplural,
      )
    } else if cs != none {
      (
        short: short,
        en: none,
        cs: cs,
        plural: plural_form,
        longplural: longplural,
        csplural: csplural,
      )
    } else if text_value != none {
      (
        short: short,
        en: none,
        cs: text_value,
        plural: plural_form,
        longplural: longplural,
        csplural: csplural,
      )
    } else {
      panic-local(
        "Neplatná zkratka. U tabulky použijte klíče `en`/`cs` nebo `value`.",
        "Invalid acronym. For table entries use keys `en`/`cs` or `value`.",
      )
    }
  } else {
    panic-local(
      "Nepodporovaná hodnota zkratky.",
      "Unsupported acronym value.",
    )
  }
}

#let acronym-fields-from-value(short, value) = {
  let default_short = str(short)
  if type(value) == dictionary {
    (
      short: str(value.at("short", default: value.at("abbr", default: default_short))),
      en: value.at("en", default: value.at("english", default: none)),
      cs: value.at(
        "cs",
        default: value.at(
          "czech",
          default: value.at("value", default: value.at("text", default: none)),
        ),
      ),
      plural: value.at("plural", default: none),
      longplural: value.at("longplural", default: value.at("en_plural", default: none)),
      csplural: value.at("csplural", default: value.at("cs_plural", default: none)),
    )
  } else if type(value) == array {
    (
      short: default_short,
      en: if value.len() > 0 { value.at(0) } else { none },
      cs: if value.len() > 1 { value.at(1) } else { none },
      plural: none,
      longplural: none,
      csplural: none,
    )
  } else if type(value) == str {
    (
      short: default_short,
      en: none,
      cs: value,
      plural: none,
      longplural: none,
      csplural: none,
    )
  } else {
    (
      short: default_short,
      en: none,
      cs: none,
      plural: none,
      longplural: none,
      csplural: none,
    )
  }
}

#let normalize-acronyms-dictionary(dict) = {
  let result = (:)
  for (short, value) in dict.pairs() {
    let key = if type(value) == dictionary {
      let alias = value.at(
        "short",
        default: value.at("abbr", default: value.at("key", default: none)),
      )
      if alias != none { str(alias) } else { str(short) }
    } else {
      str(short)
    }
    result.insert(key, normalize-acronyms-value(value))
  }
  result
}

#let extract-acronyms-from-document(document) = {
  let nested = document.at("acronyms", default: none)
  if nested != none {
    if type(nested) != dictionary {
      panic-local(
        "V TOML musí být `[acronyms]` slovník.",
        "In TOML, `[acronyms]` must be a dictionary.",
      )
    }
    normalize-acronyms-dictionary(nested)
  } else {
    // Pravidlo: Podporuje i tabulky na nejvyšší úrovni (`[ISO]`, `[AČR]`, ...).
    let top_level_tables = document
      .pairs()
      .filter(((short, value)) => type(value) == dictionary)

    if top_level_tables.len() > 0 {
      let result = (:)
      for (short, value) in top_level_tables {
        let key = value.at(
          "short",
          default: value.at("abbr", default: value.at("key", default: short)),
        )
        result.insert(str(key), normalize-acronyms-value(value))
      }
      result
    } else {
      // Pravidlo: Zachová původní slovníkový formát.
      normalize-acronyms-dictionary(document)
    }
  }
}

#let normalize-toml-table-headers(text) = {
  text
    .split("\n")
    .map(line => {
      let trimmed = line.trim()
      if trimmed.starts-with("[") and trimmed.ends-with("]") {
        let header = trimmed.slice(1, trimmed.len() - 1).trim()
        // Pravidlo: Přepíše pouze jednoduché hlavičky bez tečkové cesty.
        if not header.contains(".") {
          "[\"" + header + "\"]"
        } else {
          line
        }
      } else {
        line
      }
    })
    .join("\n")
}

// Funkce: normalize-glossary-entries-dictionary
// Účel: Normalizuje sjednocený slovník glosáře (TOML -> interní slovník).
#let normalize-glossary-entries-dictionary(dict) = {
  let result = (:)
  for (raw_key, value) in dict.pairs() {
    if type(value) == dictionary {
      let key = str(raw_key)
      let short = str(value.at("short", default: key))
      result.insert(
        key,
        (
          key: key,
          short: short,
          en: value.at("en", default: value.at("english", default: none)),
          cs: value.at("cs", default: value.at("czech", default: none)),
          plural: value.at("plural", default: none),
          longplural: value.at("longplural", default: value.at("en_plural", default: none)),
          csplural: value.at("csplural", default: value.at("cs_plural", default: none)),
          glossary: value.at(
            "glossary",
            default: value.at("description", default: none),
          ),
        ),
      )
    }
  }
  result
}

#let extract-glossary-entries-from-document(document) = {
  let nested = document.at("entries", default: none)
  if nested != none {
    if type(nested) != dictionary {
      panic-local(
        "V TOML musí být `[entries]` slovník.",
        "In TOML, `[entries]` must be a dictionary.",
      )
    }
    normalize-glossary-entries-dictionary(nested)
  } else {
    let top_level_tables = document
      .pairs()
      .filter(((entry_key, value)) => type(value) == dictionary)

    if top_level_tables.len() > 0 {
      let result = (:)
      for (entry_key, value) in top_level_tables {
        result.insert(
          str(entry_key),
          (
            key: str(entry_key),
            short: str(value.at("short", default: str(entry_key))),
            en: value.at("en", default: value.at("english", default: none)),
            cs: value.at("cs", default: value.at("czech", default: none)),
            plural: value.at("plural", default: none),
            longplural: value.at("longplural", default: value.at("en_plural", default: none)),
            csplural: value.at("csplural", default: value.at("cs_plural", default: none)),
            glossary: value.at(
              "glossary",
              default: value.at("description", default: none),
            ),
          ),
        )
      }
      result
    } else {
      normalize-glossary-entries-dictionary(document)
    }
  }
}

#let normalize-glossary-entries-input(input) = {
  if input == false or input == none {
    false
  } else if type(input) == dictionary {
    extract-glossary-entries-from-document(input)
  } else if type(input) == raw {
    let parsed = toml(bytes(normalize-toml-table-headers(input.text)))
    extract-glossary-entries-from-document(parsed)
  } else if type(input) == str {
    let parsed = toml(bytes(normalize-toml-table-headers(input)))
    extract-glossary-entries-from-document(parsed)
  } else {
    panic-local(
      "Nepodporovaný formát sjednoceného glosáře.",
      "Unsupported unified glossary format.",
    )
  }
}

// Alias: Kratší název kvůli kompatibilitě s některými LSP klienty.
#let normalize-glossary-input(input) = normalize-glossary-entries-input(input)

#let normalize-acronyms-input(input) = {
  if input == false or input == none {
    false
  } else if type(input) == dictionary {
    extract-acronyms-from-document(input)
  } else if type(input) == array {
    let result = (:)
    for row in input {
      if type(row) != array or row.len() < 2 or row.len() > 3 {
        panic-local(
          "Neplatný řádek zkratek. Očekává se: (zkratka, význam) nebo (zkratka, EN, CS).",
          "Invalid acronym row. Expected: (acronym, meaning) or (acronym, EN, CS).",
        )
      }
      let short = str(row.at(0))
      if row.len() == 2 {
        result.insert(short, row.at(1))
      } else {
        result.insert(short, (row.at(1), row.at(2)))
      }
    }
    result
  } else if type(input) == raw {
    let parsed = toml(bytes(normalize-toml-table-headers(input.text)))
    extract-acronyms-from-document(parsed)
  } else if type(input) == str {
    let parsed = toml(bytes(normalize-toml-table-headers(input)))
    extract-acronyms-from-document(parsed)
  } else {
    panic-local(
      "Nepodporovaný formát zkratek.",
      "Unsupported acronym format.",
    )
  }
}

// Funkce: normalize-terms-value
// Účel: Normalizuje jednu položku pojmu do interního tvaru.
#let normalize-terms-value(key, value) = {
  if type(value) == str {
    (
      short: key,
      long: none,
      description: value,
      plural: none,
      longplural: none,
    )
  } else if type(value) == array {
    if value.len() == 1 {
      (
        short: key,
        long: none,
        description: value.at(0),
        plural: none,
        longplural: none,
      )
    } else if value.len() == 2 {
      (
        short: key,
        long: value.at(0),
        description: value.at(1),
        plural: none,
        longplural: none,
      )
    } else {
      panic-local(
        "Pole pojmu musí mít 1 nebo 2 položky.",
        "Term array must have 1 or 2 items.",
      )
    }
  } else if type(value) == dictionary {
    let short = value.at("short", default: value.at("abbr", default: key))
    let long = value.at(
      "long",
      default: value.at("name", default: value.at("en", default: none)),
    )
    let description = value.at(
      "description",
      default: value.at(
        "desc",
        default: value.at(
          "cs",
          default: value.at("text", default: value.at("value", default: none)),
        ),
      ),
    )

    (
      short: short,
      long: long,
      description: description,
      plural: value.at("plural", default: none),
      longplural: value.at("longplural", default: none),
    )
  } else {
    panic-local(
      "Nepodporovaná hodnota pojmu.",
      "Unsupported term value.",
    )
  }
}

#let normalize-terms-dictionary(dict) = {
  let result = (:)
  for (raw_key, value) in dict.pairs() {
    let key = str(raw_key)
    let normalized = normalize-terms-value(key, value)
    result.insert(
      key,
      (
        short: normalized.at("short", default: key),
        long: normalized.at("long", default: none),
        description: normalized.at("description", default: none),
        plural: normalized.at("plural", default: none),
        longplural: normalized.at("longplural", default: none),
      ),
    )
  }
  result
}

#let extract-terms-from-document(document) = {
  let nested = document.at("terms", default: none)
  if nested != none {
    if type(nested) != dictionary {
      panic-local(
        "V TOML musí být `[terms]` slovník.",
        "In TOML, `[terms]` must be a dictionary.",
      )
    }
    normalize-terms-dictionary(nested)
  } else {
    let top_level_tables = document
      .pairs()
      .filter(((term_key, value)) => type(value) == dictionary)

    if top_level_tables.len() > 0 {
      let result = (:)
      for (term_key, value) in top_level_tables {
        let key = str(term_key)
        let normalized = normalize-terms-value(key, value)
        result.insert(
          key,
          (
            short: normalized.at("short", default: key),
            long: normalized.at("long", default: none),
            description: normalized.at("description", default: none),
            plural: normalized.at("plural", default: none),
            longplural: normalized.at("longplural", default: none),
          ),
        )
      }
      result
    } else {
      normalize-terms-dictionary(document)
    }
  }
}

#let normalize-terms-input(input) = {
  if input == false or input == none {
    false
  } else if type(input) == dictionary {
    extract-terms-from-document(input)
  } else if type(input) == array {
    let result = (:)
    for row in input {
      if type(row) != array or row.len() < 2 or row.len() > 3 {
        panic-local(
          "Neplatný řádek pojmů. Očekává se: (key, description) nebo (key, long, description).",
          "Invalid term row. Expected: (key, description) or (key, long, description).",
        )
      }
      let key = str(row.at(0))
      if row.len() == 2 {
        result.insert(key, (short: key, long: none, description: row.at(1), plural: none, longplural: none))
      } else {
        result.insert(
          key,
          (short: key, long: row.at(1), description: row.at(2), plural: none, longplural: none),
        )
      }
    }
    result
  } else if type(input) == raw {
    let parsed = toml(bytes(normalize-toml-table-headers(input.text)))
    extract-terms-from-document(parsed)
  } else if type(input) == str {
    let parsed = toml(bytes(normalize-toml-table-headers(input)))
    extract-terms-from-document(parsed)
  } else {
    panic-local(
      "Nepodporovaný formát glosáře pojmů.",
      "Unsupported glossary terms format.",
    )
  }
}

#let glossary-entries-to-acronyms(entries_dict) = {
  if type(entries_dict) != dictionary {
    false
  } else {
    let result = (:)
    for (entry_key, entry) in entries_dict.pairs() {
      let source_key = str(entry_key)
      let short = str(entry.at("short", default: str(entry_key)))
      let en = entry.at("en", default: none)
      let cs = entry.at("cs", default: none)
      let plural_form = entry.at("plural", default: none)
      let longplural = entry.at("longplural", default: none)
      let csplural = entry.at("csplural", default: none)
      let is_multiword_short = short.contains(" ")

      if not is_multiword_short and (en != none or cs != none) {
        result.insert(
          source_key,
          (
            short: short,
            en: en,
            cs: cs,
            plural: plural_form,
            longplural: longplural,
            csplural: csplural,
          ),
        )
      }
    }
    if result.len() == 0 { false } else { result }
  }
}

#let glossary-to-acronyms(entries_dict) = glossary-entries-to-acronyms(entries_dict)

#let glossary-entries-to-terms(entries_dict) = {
  if type(entries_dict) != dictionary {
    false
  } else {
    let result = (:)
    for (entry_key, entry) in entries_dict.pairs() {
      let glossary_text = entry.at("glossary", default: none)
      if glossary_text != none {
        let source_key = str(entry_key)
        let short = str(entry.at("short", default: source_key))
        let term_value = (
          short: short,
          long: none,
          description: glossary_text,
          plural: entry.at("plural", default: none),
          longplural: entry.at("longplural", default: none),
        )
        result.insert(source_key, term_value)
      }
    }
    if result.len() == 0 { false } else { result }
  }
}

#let glossary-to-terms(entries_dict) = glossary-entries-to-terms(entries_dict)

#let acronyms-to-glossary-entries(acronyms_dict) = {
  if type(acronyms_dict) != dictionary {
    ()
  } else {
    acronyms_dict
      .pairs()
      .sorted(
        key: ((key, value)) => str(value.at("short", default: str(key))).normalize(form: "nfd"),
      )
      .map(((raw_key, value)) => {
        let key = str(raw_key)
        let fields = acronym-fields-from-value(key, value)
        let short = str(fields.at("short", default: key))
        let english = fields.at("en", default: none)
        let czech = fields.at("cs", default: none)
        let plural_raw = fields.at("plural", default: none)
        let plural_form = if plural_raw != none { plural_raw } else { short }
        let longplural = fields.at("longplural", default: none)

        (
          key: key,
          short: short,
          long: english,
          description: czech,
          plural: plural_form,
          longplural: longplural,
          group: acronyms-group,
        )
      })
  }
}

#let terms-to-glossary-entries(terms_dict) = {
  if type(terms_dict) != dictionary {
    ()
  } else {
    terms_dict
      .pairs()
      .sorted(key: ((key, _)) => str(key).normalize(form: "nfd"))
      .map(((key, value)) => {
        (
          key: str(key),
          short: value.at("short", default: str(key)),
          long: value.at("long", default: none),
          description: value.at("description", default: none),
          plural: value.at("plural", default: none),
          longplural: value.at("longplural", default: none),
          group: terms-group,
        )
      })
  }
}

#let filter-entries-by-usage(entries) = {
  entries.filter(entry => count-refs(str(entry.at("key", default: ""))) > 0)
}

#let get-used-acronym-entries(acronyms_dict) = {
  let entries = if type(acronyms_dict) == dictionary and acronyms_dict.len() > 0 {
    acronyms-to-glossary-entries(acronyms_dict)
  } else {
    ()
  }
  filter-entries-by-usage(entries)
}

#let get-used-term-entries(terms_dict) = {
  let entries = if type(terms_dict) == dictionary and terms_dict.len() > 0 {
    terms-to-glossary-entries(terms_dict)
  } else {
    ()
  }
  filter-entries-by-usage(entries)
}

#let has-used-acronyms(acronyms_dict) = get-used-acronym-entries(acronyms_dict).len() > 0
#let has-used-terms(terms_dict) = get-used-term-entries(terms_dict).len() > 0

#let has-glossary-value(value) = {
  value != none and value != [] and (type(value) != str or value.trim().len() > 0)
}

#let print-terms-title-bold(entry) = {
  let short = entry.at("short", default: none)
  let long = entry.at("long", default: none)
  let txt = strong.with(delta: 200)

  if has-glossary-value(short) and has-glossary-value(long) {
    txt(short + [ -- ] + long)
  } else if has-glossary-value(long) {
    txt(long)
  } else {
    txt(short)
  }
}

// Funkce: generate-acronyms-list
// Účel: Vykreslí seznam použitých zkratek.
#let generate-acronyms-list(acronyms_dict) = {
  let entries = get-used-acronym-entries(acronyms_dict)

  if entries.len() > 0 {
    let sorted = entries
      .sorted(key: entry => str(entry.at("short", default: entry.at("key"))).normalize(form: "nfd"))
    grid(
      columns: (auto, 1fr),
      column-gutter: 5mm,
      row-gutter: 5mm,
      ..sorted
        .map(entry => {
          let short = str(entry.at("short", default: entry.at("key")))
          let entry_key = str(entry.at("key", default: short))
          let long = entry.at("long", default: none)
          let description = entry.at("description", default: none)
          let meaning = if long != none { long } else { description }
          let translation = if long != none {
            description
          } else {
            none
          }
          let explanation = if meaning == none {
            none
          } else if translation == none {
            [#meaning]
          } else {
            stack(
              spacing: 5mm,
              [#meaning],
              [#translation],
            )
          }

          if explanation == none {
            ()
          } else {
            (
              [#strong(short)#label(acronym-label-prefix + entry_key)],
              explanation,
            )
          }
        })
        .flatten(),
    )
  }
}

// Funkce: generate-terms-list
// Účel: Vykreslí seznam použitých pojmů.
#let generate-terms-list(terms_dict) = {
  let entries = get-used-term-entries(terms_dict)

  if entries.len() > 0 {
    print-glossary(
      entries,
      show-all: true,
      minimum-refs: 0,
      disable-back-references: true,
      user-print-group-heading: (..args) => [],
      user-group-break: () => [],
      user-print-title: print-terms-title-bold,
    )
  }
}

#let merge-registry-entries(acronym_entries, term_entries) = {
  let merged = (:)

  for entry in term_entries {
    merged.insert(str(entry.at("key")), entry)
  }

  for entry in acronym_entries {
    let key = str(entry.at("key"))
    let existing = merged.at(key, default: none)
    if existing == none {
      merged.insert(key, entry)
    } else {
      merged.insert(
        key,
        (
          key: key,
          short: existing.at("short", default: entry.at("short", default: key)),
          long: if existing.at("long", default: none) != none {
            existing.at("long")
          } else {
            entry.at("long", default: none)
          },
          description: existing.at(
            "description",
            default: entry.at("description", default: none),
          ),
          plural: existing.at("plural", default: entry.at("plural", default: none)),
          longplural: existing.at(
            "longplural",
            default: entry.at("longplural", default: none),
          ),
          group: existing.at("group", default: entry.at("group", default: "")),
        ),
      )
    }
  }

  merged.values()
}

// Funkce: init-glossary-runtime
// Účel: Inicializuje registry a zaregistruje položky pro glossarium.
#let init-glossary-runtime(acronyms, terms: false) = {
  let safe_acronyms = if type(acronyms) == dictionary { acronyms } else { (:) }
  let safe_terms = if type(terms) == dictionary { terms } else { (:) }

  let acronym_entries = acronyms-to-glossary-entries(safe_acronyms)
  let term_entries = terms-to-glossary-entries(safe_terms)
  let all_entries = merge-registry-entries(acronym_entries, term_entries)

  acronyms-registry.update(safe_acronyms)
  terms-registry.update(safe_terms)

  if all_entries.len() > 0 {
    register-glossary(all_entries)
  }
}

// Alias: Zpětně kompatibilní inicializace pouze pro zkratky.
#let init-acronyms-runtime(acronyms) = init-glossary-runtime(acronyms, terms: false)

#let get-dictionary-keys(definitions) = {
  let keys = (:)
  for (raw_key, value) in definitions.pairs() {
    let key = str(raw_key)
    keys.insert(lower(key), key)
    if type(value) == dictionary {
      let short = value.at("short", default: none)
      if short != none {
        let short_key = str(short)
        // Pravidlo: V nápovědě preferuje `short` před interním klíčem.
        keys.insert(lower(short_key), short_key)
      }
    }
  }
  keys
    .values()
    .sorted(key: item => lower(item))
}

#let find-key-case-insensitive(raw_key, definitions) = {
  let key = str(raw_key)
  if definitions.at(key, default: none) != none {
    key
  } else {
    let lookup = lower(key)
    let matches = definitions
      .pairs()
      .map(((candidate, value)) => str(candidate))
      .filter(candidate => lower(candidate) == lookup)

    if matches.len() == 1 {
      matches.at(0)
    } else if matches.len() > 1 {
      panic-local(
        "Nejednoznačný klíč `" + key + "`. Odpovídá více položek: "
          + matches.join(", "),
        "Ambiguous key `" + key + "`. Multiple entries match: " + matches.join(", "),
      )
    } else {
      none
    }
  }
}

#let find-key-by-short-case-insensitive(raw_key, definitions) = {
  let lookup = lower(str(raw_key))
  let matches = definitions
    .pairs()
    .filter(((candidate, value)) => {
      if type(value) != dictionary {
        false
      } else {
        let short = value.at("short", default: none)
        short != none and lower(str(short)) == lookup
      }
    })
    .map(((candidate, value)) => str(candidate))

  if matches.len() == 1 {
    matches.at(0)
  } else if matches.len() > 1 {
    panic-local(
      "Nejednoznačný klíč `" + str(raw_key)
        + "`. Odpovídá více položek (podle `short`): " + matches.join(", "),
      "Ambiguous key `" + str(raw_key)
        + "`. Multiple entries match (by `short`): " + matches.join(", "),
    )
  } else {
    none
  }
}

#let find-key-or-short-case-insensitive(raw_key, definitions) = {
  let direct = find-key-case-insensitive(raw_key, definitions)
  if direct != none {
    direct
  } else {
    find-key-by-short-case-insensitive(raw_key, definitions)
  }
}

#let panic-unknown-key(
  kind_cs,
  kind_en,
  key,
  definitions,
  unknown_cs: "Neznámý",
  unknown_en: "Unknown",
) = context {
  let keys = get-dictionary-keys(definitions)
  let lookup = lower(key)
  let prefix_matches = keys
    .filter(candidate => lower(candidate).starts-with(lookup))

  if text.lang == "en" {
    if prefix_matches.len() > 0 {
      panic(
        unknown_en + " " + kind_en + " `" + key
          + "`. Possible entries starting with `" + key + "`: "
          + prefix_matches.join(", "),
      )
    } else if keys.len() > 0 {
      panic(
        unknown_en + " " + kind_en + " `" + key + "`. Available entries: "
          + keys.join(", "),
      )
    } else {
      panic(unknown_en + " " + kind_en + " `" + key + "`. The list is empty.")
    }
  } else {
    if prefix_matches.len() > 0 {
      panic(
        unknown_cs + " " + kind_cs + " `" + key
          + "`. Možné položky začínající na `" + key + "`: "
          + prefix_matches.join(", "),
      )
    } else if keys.len() > 0 {
      panic(
        unknown_cs + " " + kind_cs + " `" + key + "`. Dostupné položky: "
          + keys.join(", "),
      )
    } else {
      panic(unknown_cs + " " + kind_cs + " `" + key + "`. Seznam je prázdný.")
    }
  }
}

#let resolve-known-key(
  kind_cs,
  kind_en,
  raw_key,
  definitions,
  unknown_cs: "Neznámý",
  unknown_en: "Unknown",
) = {
  let key = str(raw_key)
  let resolved = find-key-or-short-case-insensitive(key, definitions)
  if resolved == none {
    panic-unknown-key(
      kind_cs,
      kind_en,
      key,
      definitions,
      unknown_cs: unknown_cs,
      unknown_en: unknown_en,
    )
  }
  resolved
}

#let normalize-trm-style(style) = {
  if style == none or style == singular or style == "singular" or style == "default" {
    singular
  } else if style == plural or style == "plural" {
    plural
  } else if style == first or style == "first" {
    first
  } else if style == first-plural or style == "first_plural" or style == "first-plural" {
    first-plural
  } else {
    panic-local(
      "Neznámý styl `" + str(style)
        + "`. Použijte `singular`, `plural`, `first` nebo `first_plural`.",
      "Unknown style `" + str(style)
        + "`. Use `singular`, `plural`, `first`, or `first_plural`.",
    )
  }
}

#let normalize-trm-case(case) = {
  if type(case) == int and case >= 1 and case <= 7 {
    case
  } else {
    panic-local(
      "Neznámý pád `" + str(case) + "`. Použijte číslo 1 až 7.",
      "Unknown case `" + str(case) + "`. Use numbers 1 to 7.",
    )
  }
}

#let apply-word-case-template(template, value) = {
  if type(template) != str or type(value) != str or value.len() == 0 {
    value
  } else if template == upper(template) {
    upper(value)
  } else if template.at(0) == upper(template.at(0)) {
    upper(value.at(0)) + value.slice(1)
  } else {
    value
  }
}

#let acronym-label-id(key) = acronym-label-prefix + str(key)

#let link-to-acronym-entry(key, text) = context {
  let target = label(acronym-label-id(key))
  let has_target = query(selector(target)).len() > 0
  if has_target {
    link(target, text)
  } else {
    text
  }
}

#let decline-czech-first-word(word, grammatical_case: 1, plural_form: false) = {
  if type(word) != str or word.len() == 0 {
    word
  } else {
    let lower_word = lower(word)

    if lower_word.ends-with("a") {
      let stem = lower_word.slice(0, lower_word.len() - 1)
      let palatal_case = if stem.ends-with("d") or stem.ends-with("t") or stem.ends-with("n") {
        "ě"
      } else {
        "e"
      }
      let ending = if plural_form {
        if grammatical_case == 1 { "y" } else if grammatical_case == 2 { "" } else if grammatical_case == 3 { "ám" } else if grammatical_case == 4 { "y" } else if grammatical_case == 5 { "y" } else if grammatical_case == 6 { "ách" } else { "ami" }
      } else {
        if grammatical_case == 1 { "a" } else if grammatical_case == 2 { "y" } else if grammatical_case == 3 { palatal_case } else if grammatical_case == 4 { "u" } else if grammatical_case == 5 { "o" } else if grammatical_case == 6 { palatal_case } else { "ou" }
      }
      apply-word-case-template(word, stem + ending)
    } else if lower_word.ends-with("e") {
      let stem = lower_word.slice(0, lower_word.len() - 1)
      let ending = if plural_form {
        if grammatical_case == 1 { "e" } else if grammatical_case == 2 { "i" } else if grammatical_case == 3 { "ím" } else if grammatical_case == 4 { "e" } else if grammatical_case == 5 { "e" } else if grammatical_case == 6 { "ích" } else { "emi" }
      } else {
        if grammatical_case == 1 { "e" } else if grammatical_case == 2 { "e" } else if grammatical_case == 3 { "i" } else if grammatical_case == 4 { "i" } else if grammatical_case == 5 { "e" } else if grammatical_case == 6 { "i" } else { "i" }
      }
      apply-word-case-template(word, stem + ending)
    } else {
      word
    }
  }
}

#let decline-czech-phrase(phrase, grammatical_case: 1, plural_form: false) = {
  if type(phrase) != str {
    phrase
  } else {
    let words = phrase.split(" ")
    if words.len() == 0 {
      phrase
    } else {
      let first_word = words.at(0)
      let declined_first = decline-czech-first-word(
        first_word,
        grammatical_case: grammatical_case,
        plural_form: plural_form,
      )

      if words.len() == 1 {
        declined_first
      } else {
        declined_first + " " + words.slice(1).join(" ")
      }
    }
  }
}

#let resolve-acronym-long-form(
  fields,
  grammatical_case: 1,
  plural_form: false,
) = context {
  let czech = fields.at("cs", default: none)
  let czech_plural = fields.at("csplural", default: none)
  let english = fields.at("en", default: none)
  let english_plural = fields.at("longplural", default: none)

  if text.lang == "cs" and czech != none {
    if plural_form and type(czech_plural) == str and grammatical_case == 1 {
      czech_plural
    } else {
      decline-czech-phrase(
        czech,
        grammatical_case: grammatical_case,
        plural_form: plural_form,
      )
    }
  } else if english != none {
    if plural_form {
      if english_plural != none {
        english_plural
      } else if type(english) == str {
        english + "s"
      } else {
        english
      }
    } else {
      english
    }
  } else if czech != none {
    decline-czech-phrase(
      czech,
      grammatical_case: grammatical_case,
      plural_form: plural_form,
    )
  } else {
    none
  }
}

#let build-acronym-first-display(
  fields,
  short_display,
  grammatical_case: 1,
  plural_form: false,
) = {
  let czech = fields.at("cs", default: none)
  let czech_plural = fields.at("csplural", default: none)
  let english = fields.at("en", default: none)
  let english_plural = fields.at("longplural", default: none)

  let czech_form = if czech != none {
    if plural_form and type(czech_plural) == str and grammatical_case == 1 {
      czech_plural
    } else {
      decline-czech-phrase(
        czech,
        grammatical_case: grammatical_case,
        plural_form: plural_form,
      )
    }
  } else {
    none
  }

  let english_form = if english != none {
    if plural_form {
      if english_plural != none {
        english_plural
      } else if type(english) == str {
        english + "s"
      } else {
        english
      }
    } else {
      english
    }
  } else {
    none
  }

  if czech_form != none and english_form != none {
    [#czech_form (#english_form - #short_display)]
  } else if czech_form != none {
    [#czech_form (#short_display)]
  } else if english_form != none {
    [#english_form (#short_display)]
  } else {
    [(#short_display)]
  }
}

// Funkce: acronym
// Účel: Vloží zkratku do textu (první použití rozvine, další použijí short tvar).
#let acronym(short, force-first: false, grammatical_case: 1) = context {
  let requested_key = str(short)

  let definitions_raw = acronyms-registry.get()
  let definitions = if type(definitions_raw) == dictionary {
    definitions_raw
  } else {
    (:)
  }
  let key = resolve-known-key(
    "zkratka",
    "acronym",
    requested_key,
    definitions,
    unknown_cs: "Neznámá",
    unknown_en: "Unknown",
  )
  let value = definitions.at(key)
  let fields = acronym-fields-from-value(key, value)
  let short_form = str(fields.at("short", default: key))
  let first_display = build-acronym-first-display(
    fields,
    short_form,
    grammatical_case: grammatical_case,
    plural_form: false,
  )
  let show_first = force-first or is-first(key)

  if not show_first {
    let rendered = gls(key, first: false, link: false)
    link-to-acronym-entry(key, rendered)
  } else {
    let rendered = gls(key, display: first_display, link: false)
    link-to-acronym-entry(key, rendered)
  }
}

#let acronym-plural(short, force-first: false, grammatical_case: 1) = context {
  let requested_key = str(short)

  let definitions_raw = acronyms-registry.get()
  let definitions = if type(definitions_raw) == dictionary {
    definitions_raw
  } else {
    (:)
  }
  let key = resolve-known-key(
    "zkratka",
    "acronym",
    requested_key,
    definitions,
    unknown_cs: "Neznámá",
    unknown_en: "Unknown",
  )
  let value = definitions.at(key)
  let fields = acronym-fields-from-value(key, value)
  let short_form = str(fields.at("short", default: key))
  let short_plural_raw = fields.at("plural", default: none)
  let short_plural = if short_plural_raw != none {
    short_plural_raw
  } else {
    short_form
  }
  let first_display = build-acronym-first-display(
    fields,
    short_plural,
    grammatical_case: grammatical_case,
    plural_form: true,
  )
  let show_first = force-first or is-first(key)

  if not show_first {
    let rendered = glspl(key, first: false, link: false)
    link-to-acronym-entry(key, rendered)
  } else {
    let rendered = glspl(key, display: first_display, link: false)
    link-to-acronym-entry(key, rendered)
  }
}

// Funkce: term
// Účel: Vloží pojem do textu přes glossarium.
#let term(key, force-first: false) = context {
  let requested_key = str(key)

  let definitions_raw = terms-registry.get()
  let definitions = if type(definitions_raw) == dictionary {
    definitions_raw
  } else {
    (:)
  }
  let term_key = resolve-known-key("pojem", "term", requested_key, definitions)

  if force-first {
    gls(term_key, first: true, link: false)
  } else {
    gls(term_key, link: false)
  }
}

#let term-plural(key, force-first: false) = context {
  let requested_key = str(key)

  let definitions_raw = terms-registry.get()
  let definitions = if type(definitions_raw) == dictionary {
    definitions_raw
  } else {
    (:)
  }
  let term_key = resolve-known-key("pojem", "term", requested_key, definitions)

  if force-first {
    glspl(term_key, first: true, link: false)
  } else {
    glspl(term_key, link: false)
  }
}

// Funkce: trm
// Účel: Jednotné API pro zkratky i pojmy (`singular`, `plural`, `first`, `first_plural`).
// Jak:
// - `style` řídí tvar.
// - `force: true|"first"` vynutí první tvar i při opakovaném použití.
#let trm(key, style: singular, case: 1, force: none) = context {
  let requested_key = str(key)
  let resolved_style = normalize-trm-style(style)
  let resolved_case = normalize-trm-case(case)
  let force_first = force == true or force == first or force == "first"
  let effective_style = if force_first {
    if resolved_style == plural or resolved_style == first-plural {
      first-plural
    } else {
      first
    }
  } else {
    resolved_style
  }

  let acronyms_raw = acronyms-registry.get()
  let acronyms = if type(acronyms_raw) == dictionary { acronyms_raw } else { (:) }
  let terms_raw = terms-registry.get()
  let terms = if type(terms_raw) == dictionary { terms_raw } else { (:) }

  let acronym_key = find-key-or-short-case-insensitive(requested_key, acronyms)
  let term_key = find-key-or-short-case-insensitive(requested_key, terms)

  if acronym_key != none {
    if effective_style == plural {
      acronym-plural(acronym_key, grammatical_case: resolved_case)
    } else if effective_style == first {
      acronym(acronym_key, force-first: true, grammatical_case: resolved_case)
    } else if effective_style == first-plural {
      acronym-plural(
        acronym_key,
        force-first: true,
        grammatical_case: resolved_case,
      )
    } else {
      acronym(acronym_key, grammatical_case: resolved_case)
    }
  } else if term_key != none {
    if effective_style == plural {
      term-plural(term_key)
    } else if effective_style == first {
      term(term_key, force-first: true)
    } else if effective_style == first-plural {
      term-plural(term_key, force-first: true)
    } else {
      term(term_key)
    }
  } else {
    let merged = (:)
    for (candidate, value) in acronyms.pairs() {
      merged.insert(str(candidate), value)
    }
    for (candidate, value) in terms.pairs() {
      if merged.at(str(candidate), default: none) == none {
        merged.insert(str(candidate), value)
      }
    }
    panic-unknown-key("pojem nebo zkratka", "term or acronym", requested_key, merged)
  }
}

// Alias: Krátké zkratky pro pohodlné použití v textu.
#let acr = acronym
#let trmpl(key) = trm(key, style: plural)
