#import "@preview/drafting:0.2.2": margin-note, note-outline, set-margin-note-defaults
#import "../utils.typ": is-draft-mode

// Funkce: setup-draft-todos
// Účel: Nastaví balíček drafting pro TODO poznámky v pravém okraji.
#let setup-draft-todos() = {
  set-margin-note-defaults(side: right, hidden: false)
}

// Funkce: todo
// Účel: Jednoduché TODO, které je viditelné pouze při `draft: true`.
// Jak: V draft režimu deleguje na `margin-note`, jinak nevrací žádný výstup.
#let todo(..args) = context {
  if is-draft-mode() {
    margin-note(side: right, ..args)
  } else {
    []
  }
}

// Funkce: todo-outline
// Účel: Vykreslí přehled TODO poznámek pouze v draft režimu.
#let todo-outline(..args) = context {
  if is-draft-mode() {
    note-outline(..args)
  } else {
    []
  }
}
