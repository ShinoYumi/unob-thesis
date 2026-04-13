#import "./data.typ": translations, supported_faculties, supported_thesis_types, faculty_names, city_names, thesis_type_forms

// Funkce: is-supported-faculty
// Účel: Ověří, zda je fakulta v podporovaném výčtu.
#let is-supported-faculty(faculty) = {
  supported_faculties.any(item => item == faculty)
}

// Funkce: is-supported-thesis-type
// Účel: Ověří, zda je typ práce podporovaný.
#let is-supported-thesis-type(thesis_type) = {
  let candidate = lower(str(thesis_type))
  supported_thesis_types.any(item => item == candidate)
}

// Funkce: resolve-lang
// Účel: Přeloží `lang: auto` na konkrétní kód jazyka podle aktuálního dokumentu.
#let resolve-lang(lang: auto) = {
  let doc_lang = context text.lang
  if lang == auto {
    if doc_lang == "en" { "en" } else { "cs" }
  } else if lang == "en" {
    "en"
  } else {
    "cs"
  }
}

// Funkce: t
// Účel: Vrátí lokalizovaný text podle klíče.
#let t(key, lang: auto) = {
  let loc = resolve-lang(lang: lang)
  let message = translations.at(key, default: none)
  if message == none {
    if loc == "en" {
      panic("Missing translation key: " + key)
    } else {
      panic("Chybí překladový klíč: " + key)
    }
  }
  if type(message) == dictionary {
    message.at(loc, default: message.at("cs", default: none))
  } else {
    message
  }
}

// Funkce: faculty-name
// Účel: Vrátí název fakulty pro zadaný pád/variantu.
#let faculty-name(faculty, variant: 1, lang: auto) = {
  let loc = resolve-lang(lang: lang)

  let entry = faculty_names.at(faculty, default: none)
  if entry == none {
    panic(t("error_unsupported_faculty", lang: loc))
  }

  if variant == 1 {
    entry.at(loc).at(0)
  } else if variant == 2 {
    entry.at(loc).at(1)
  } else {
    panic(t("error_unsupported_faculty_variant", lang: loc))
  }
}

// Funkce: city-name
// Účel: Vrátí název města fakulty pro zadanou variantu.
#let city-name(faculty, variant: 1, lang: auto) = {
  let loc = resolve-lang(lang: lang)

  let entry = city_names.at(faculty, default: none)
  if entry == none {
    panic(t("error_unsupported_faculty", lang: loc))
  }

  if variant == 1 {
    entry.at(0)
  } else if variant == 2 {
    entry.at(1)
  } else {
    panic(t("error_unsupported_city_variant", lang: loc))
  }
}

// Funkce: normalize-thesis-type
// Účel: Normalizuje typ práce na interní hodnotu.
#let normalize-thesis-type(thesis_type) = {
  let loc = context if text.lang == "en" { "en" } else { "cs" }

  if type(thesis_type) != str {
    panic(t("error_thesis_type_must_be_string", lang: loc))
  }

  let candidate = lower(thesis_type)
  let supported = supported_thesis_types.any(item => item == candidate)
  if not supported {
    panic(t("error_unsupported_thesis_type", lang: loc))
  }
  candidate
}

// Funkce: thesis-type-name
// Účel: Vrátí lokalizovaný název typu práce pro zadaný tvar.
#let thesis-type-name(thesis_type, variant: 1, lang: auto) = {
  let loc = resolve-lang(lang: lang)

  let normalized = normalize-thesis-type(thesis_type)
  let entry = thesis_type_forms.at(normalized, default: none)
  if entry == none {
    if loc == "en" {
      panic("Missing thesis type mapping for `" + normalized + "`.")
    } else {
      panic("Chybí mapování typu práce pro `" + normalized + "`.")
    }
  }

  if variant >= 1 and variant <= 3 {
    entry.at(loc).at(variant - 1)
  } else {
    panic(t("error_unsupported_thesis_type_variant", lang: loc))
  }
}

// Funkce: thesis-type-is-bachelor-or-master
// Účel: Ověří, zda je typ práce bakalářský nebo magisterský.
#let thesis-type-is-bachelor-or-master(thesis_type) = {
  let normalized = normalize-thesis-type(thesis_type)
  normalized == "bachelor" or normalized == "master"
}

// Funkce: thesis-type-is-doctoral
// Účel: Ověří, zda je typ práce doktorský.
#let thesis-type-is-doctoral(thesis_type) = {
  normalize-thesis-type(thesis_type) == "doctoral"
}
