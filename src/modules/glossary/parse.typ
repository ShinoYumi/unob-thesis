#import "./validate.typ": panic-local, key-has-disallowed-chars

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

// Interní helper: Array vstup pro zkratky.
#let _acronyms_array_input(input) = {
  let result = (:)
  for row in input {
    if type(row) != array or row.len() < 2 or row.len() > 3 {
      panic-local(
        "Neplatný řádek zkratek. Očekává se: (zkratka, význam) nebo (zkratka, EN, CS).",
        "Invalid acronym row. Expected: (acronym, meaning) or (acronym, EN, CS).",
      )
    }
    let short = str(row.at(0))
    result.insert(short, if row.len() == 2 { row.at(1) } else { (row.at(1), row.at(2)) })
  }
  result
}

// Interní helper: Sdílená normalize pipeline pro acronyms i terms.
#let _normalize_entries_input(input, extract_fn, array_fn, label_cs, label_en) = {
  if input == false or input == none { false }
  else if type(input) == dictionary { extract_fn(input) }
  else if type(input) == array { array_fn(input) }
  else if type(input) == raw {
    extract_fn(toml(bytes(normalize-toml-table-headers(input.text))))
  } else if type(input) == str {
    extract_fn(toml(bytes(normalize-toml-table-headers(input))))
  } else {
    panic-local(
      "Nepodporovaný formát " + label_cs + ".",
      "Unsupported " + label_en + " format.",
    )
  }
}

#let normalize-acronyms-input(input) = _normalize_entries_input(
  input, extract-acronyms-from-document, _acronyms_array_input, "zkratek", "acronym",
)

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

// Interní helper: Array vstup pro pojmy.
#let _terms_array_input(input) = {
  let result = (:)
  for row in input {
    if type(row) != array or row.len() < 2 or row.len() > 3 {
      panic-local(
        "Neplatný řádek pojmů. Očekává se: (key, description) nebo (key, long, description).",
        "Invalid term row. Expected: (key, description) or (key, long, description).",
      )
    }
    let key = str(row.at(0))
    result.insert(key, if row.len() == 2 {
      (short: key, long: none, description: row.at(1), plural: none, longplural: none)
    } else {
      (short: key, long: row.at(1), description: row.at(2), plural: none, longplural: none)
    })
  }
  result
}

#let normalize-terms-input(input) = _normalize_entries_input(
  input, extract-terms-from-document, _terms_array_input, "pojmů", "term",
)

// Interní helper: Sdílená iterace sjednoceného glosáře.
// `transform(source_key, entry)` vrátí hodnotu pro vložení, nebo `none` pro přeskočení.
#let _entries_to_dict(entries_dict, transform) = {
  if type(entries_dict) != dictionary { return false }
  let result = (:)
  for (entry_key, entry) in entries_dict.pairs() {
    let source_key = str(entry_key)
    let value = transform(source_key, entry)
    if value != none { result.insert(source_key, value) }
  }
  if result.len() == 0 { false } else { result }
}

// Funkce: glossary-entries-to-acronyms / glossary-to-acronyms
// Účel: Převede sjednocený glosář na slovník zkratek.
#let glossary-entries-to-acronyms(entries_dict) = _entries_to_dict(entries_dict, (key, entry) => {
  let short = str(entry.at("short", default: key))
  let en = entry.at("en", default: none)
  let cs = entry.at("cs", default: none)
  if not short.contains(" ") and (en != none or cs != none) {
    (
      short: short,
      en: en,
      cs: cs,
      plural: entry.at("plural", default: none),
      longplural: entry.at("longplural", default: none),
      csplural: entry.at("csplural", default: none),
    )
  }
})

#let glossary-to-acronyms(entries_dict) = glossary-entries-to-acronyms(entries_dict)

// Funkce: glossary-entries-to-terms / glossary-to-terms
// Účel: Převede sjednocený glosář na slovník pojmů.
#let glossary-entries-to-terms(entries_dict) = _entries_to_dict(entries_dict, (key, entry) => {
  let glossary_text = entry.at("glossary", default: none)
  if glossary_text != none {
    (
      short: str(entry.at("short", default: key)),
      long: none,
      description: glossary_text,
      plural: entry.at("plural", default: none),
      longplural: entry.at("longplural", default: none),
    )
  }
})

#let glossary-to-terms(entries_dict) = glossary-entries-to-terms(entries_dict)
