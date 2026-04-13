#import "/src/lib.typ": thesis-with, person

#set text(lang: "cs")

#assert.eq(type(person(name: "Jan", surname: "Novák")), dictionary)

#show: thesis-with.with(
  draft: true,
  faculty: "fvl",
  thesis: (
    type: "bachelor",
    title: [Compile-only API smoke],
  ),
  author: person(name: "Jan", surname: "Novák", sex: "M"),
  supervisor: person(name: "Jana", surname: "Nováková", sex: "F"),
  assignment: false,
  acknowledgement: false,
  declaration: false,
  acronyms: false,
  terms: false,
  guide: false,
  docs: false,
)

= ÚVOD
Tento test ověřuje, že wrapper `thesis-with.with(...)` prochází kompilací.
