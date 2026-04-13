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
