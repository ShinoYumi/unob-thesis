#import "/src/lib.typ": thesis-with, person, todo
#set text(lang: "cs")

#show: thesis-with.with(
  draft: false,
  faculty: "uo",
  thesis: (
    type: "bachelor",
    title: [Compile final bez glosáře],
  ),
  author: person(name: "Jan", surname: "Novák", sex: "M"),
  supervisor: person(name: "Jana", surname: "Nováková", sex: "F"),
  assignment: false,
  acknowledgement: false,
  declaration: true,
  ai_used: false,
  acronyms: false,
  terms: false,
  outlines: (
    headings: true,
    acronyms: true,
    terms: true,
    figures: false,
    tables: false,
    equations: false,
    listings: false,
  ),
  guide: false,
  docs: false,
)

= ÚVOD
Tento test ověřuje finální sazbu bez glosáře.
#todo[Toto TODO se ve final režimu nesmí vykreslit.]
