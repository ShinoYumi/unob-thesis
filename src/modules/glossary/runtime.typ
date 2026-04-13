#import "../../vendor/glossarium/glossarium.typ": make-glossary, register-glossary, print-glossary, count-refs as count_refs, gls, glspl
#import "../../vendor/glossarium/themes/default.typ": is-first as is_first_ref
#import "./validate.typ": panic-local
#import "./parse.typ": acronym-fields-from-value

#let acronyms-group = "__acronyms"
#let terms-group = "__terms"
#let acronym-label-prefix = "__unob_acronym_list_"

// API: Veřejné helpery nad balíčkem glossarium.
#let glossary_show = make-glossary

// API: Konstanty stylů pro `trm(...)`.
#let singular = "singular"
#let plural = "plural"
#let first = "first"
#let first-plural = "first_plural"

// Stav: Sdílené registry zkratek a pojmů.
#let acronyms-registry = state("unob-acronyms-registry", (:))
#let terms-registry = state("unob-terms-registry", (:))

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
  entries.filter(entry => count_refs(str(entry.at("key", default: ""))) > 0)
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
