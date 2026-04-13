// Funkce: coalesce
// Účel: Vrátí `a`, pokud není `none`; jinak `b`.
#let coalesce(a, b) = if a != none { a } else { b }

// Funkce: has-value
// Účel: Vrátí `true`, pokud je hodnota vyplněná (není `none`, `false`, `[]` ani prázdný string).
#let has-value(value) = {
  if value == none or value == false or value == [] {
    false
  } else if type(value) == str {
    value.trim().len() > 0
  } else {
    true
  }
}

// Funkce: is-draft-mode
// Účel: Zjistí, zda je dokument v draft režimu.
// Jak: Při `draft: auto` dotazuje metadata uzel `<unob-layout-draft>`; jinak použije předanou hodnotu.
// Poznámka: Musí být volána uvnitř `context` bloku (používá `query`).
#let is-draft-mode(draft: auto) = {
  if draft != auto {
    draft == true
  } else {
    let entries = query(<unob-layout-draft>)
    entries.len() > 0 and entries.first().value == true
  }
}

// Funkce: has-person
// Účel: Vrátí `true`, pokud má osoba vyplněné alespoň jméno nebo příjmení.
#let has-person(person) = {
  if person == none {
    false
  } else {
    has-value(person.name) or has-value(person.surname)
  }
}
