#import "/src/lib.typ": *
#set text(lang: "cs")

#show: thesis-with.with(
  draft: false,
  faculty: "fvl",
  thesis: (
    type: "doctoral",
    title: [Compile annex flow],
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
    acronyms: false,
    terms: false,
    figures: false,
    tables: false,
    equations: false,
    listings: false,
  ),
  guide: false,
  docs: false,
)

= HLAVNÍ ČÁST
Text kapitoly.

#show: annex
= Ukázková příloha
Obsah přílohy.
