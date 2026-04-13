/*
Modul: src/modules/notes.typ
Co: Callout bloky pro zvýraznění poznámek v textu.
Proč: Umožní jednotný vizuální styl poznámek bez opakování stylovacích pravidel.
Jak: Barvy v `_colors`, titulky v `i18n/data.typ`; `_note()` je spojí do callout bloku.
*/

#import "./i18n/index.typ": t

// Funkce: emptyblock
// Účel: Vykreslí základní zvýrazněný blok s barvami z palety.
#let emptyblock(colors, content) = {
  set text(fill: colors.at(0))
  set par(first-line-indent: 0mm)
  block(
    width: 100%,
    inset: (x: 1em, y: 0.5em),
    radius: 0.5em,
    breakable: true,
    fill: colors.at(1),
    stroke: (paint: colors.at(2), thickness: 1pt),
    content,
  )
}

// Funkce: callout
// Účel: Vykreslí callout s titulkem a obsahem.
#let callout(title, content, colors) = {
  emptyblock(colors, [#strong(title)\ #content])
}

// State: řídí, zda se použijí barevné nebo šedé palety. Nastavuje lib.typ.
#let _notes_colored_state = state("unob-notes-colored", true)

// Funkce: setup-notes-color — volá lib.typ při sestavení dokumentu.
#let setup-notes-color(enabled) = _notes_colored_state.update(enabled)

// Data: B&W paleta — neutrální šedá pro všechny typy při `notes_colored: false`.
#let _bw_colors = (luma(20), luma(100%), luma(170))

// Data: Barevné palety callout bloků — (text 700, fill 100, stroke 300).
// Titulky jsou v i18n/data.typ pod klíči "note_*".
#let _colors = (
  warning:        (rgb("#B45309"), rgb("#FEF3C7"), rgb("#FCD34D")),
  solution:       (rgb("#047857"), rgb("#D1FAE5"), rgb("#6EE7B7")),
  idea:           (rgb("#0369A1"), rgb("#E0F2FE"), rgb("#7DD3FC")),
  todo_note:      (rgb("#6D28D9"), rgb("#EDE9FE"), rgb("#C4B5FD")),
  definition:     (rgb("#0F766E"), rgb("#CCFBF1"), rgb("#5EEAD4")),
  context_note:   (rgb("#334155"), rgb("#F1F5F9"), rgb("#CBD5E1")),
  example:        (rgb("#0E7490"), rgb("#CFFAFE"), rgb("#67E8F9")),
  method_note:    (rgb("#4338CA"), rgb("#E0E7FF"), rgb("#A5B4FC")),
  interpretation: (rgb("#1E3A8A"), rgb("#DBEAFE"), rgb("#93C5FD")),
  summary:        (rgb("#365314"), rgb("#ECFCCB"), rgb("#BEF264")),
  literature:     (rgb("#BE123C"), rgb("#FFE4E6"), rgb("#FDA4AF")),
)

// Funkce: _note — interní helper.
// Vloží metadata pro `note-outline` a pak vykreslí callout blok.
#let _note(key, i18n_key, body) = {
  [#metadata((key: key, i18n_key: i18n_key))<unob-note>]
  context {
    let c = if _notes_colored_state.get() { _colors.at(key) } else { _bw_colors }
    callout(t(i18n_key), body, c)
  }
}

// Funkce: note-outline
// Účel: Vykreslí přehled všech callout poznámek použitých v dokumentu s číslem stránky.
// Parametry:
//   title  — nadpis přehledu (content nebo none); výchozí: none
//   types  — seznam typů k zobrazení (pole klíčů, např. ("warning", "todo_note"));
//             výchozí auto = všechny typy
#let note-outline(title: none, types: auto) = context {
  let entries = query(<unob-note>)
  if types != auto {
    entries = entries.filter(e => types.contains(e.value.key))
  }
  if entries.len() == 0 { return }

  if title != none { title }

  for entry in entries {
    let loc = entry.location()
    let pg  = counter(page).at(loc).first()
    let c   = _colors.at(entry.value.key)
    link(loc,
      block(
        width: 100%,
        inset: (x: 0.8em, y: 0.35em),
        radius: 0.3em,
        fill: c.at(1),
        stroke: (paint: c.at(2), thickness: 0.7pt),
        text(fill: c.at(0), size: 9pt,
          grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            t(entry.value.i18n_key),
            str(pg),
          )
        )
      )
    )
    v(0.15em, weak: true)
  }
}

// Veřejné API.
#let warning(body)        = _note("warning",        "note_warning",        body)
#let solution(body)       = _note("solution",        "note_solution",       body)
#let idea(body)           = _note("idea",            "note_idea",           body)
#let todo-note(body)      = _note("todo_note",       "note_todo",           body)
#let definition(body)     = _note("definition",      "note_definition",     body)
#let context-note(body)   = _note("context_note",    "note_context",        body)
#let example(body)        = _note("example",         "note_example",        body)
#let method-note(body)    = _note("method_note",     "note_method",         body)
#let interpretation(body) = _note("interpretation",  "note_interpretation", body)
#let summary(body)        = _note("summary",         "note_summary",        body)
#let literature(body)     = _note("literature",      "note_literature",     body)

// Aliasy: České názvy.
#let varovani           = warning
#let reseni             = solution
#let napad              = idea
#let definice           = definition
#let kontext              = context-note
#let priklad              = example
#let metodicka-poznamka   = method-note
#let interpretace       = interpretation
#let shrnuti            = summary
#let literatura         = literature
