#import "/src/lib.typ": *
#set text(lang: "cs")

#show: thesis-with.with(
  draft: false,
  faculty: "fvt",
  programme: [Vojenské technologie],
  specialisation: [Elektronické systémy],
  thesis: (
    type: "master",
    title: [Persistent cover phase — FVT],
  ),
  author: person(
    prefix: "por.",
    name: "Jan",
    surname: "Novák",
    suffix: none,
    sex: "M",
  ),
  supervisor: person(
    prefix: "plk. doc. Ing.",
    name: "Jana",
    surname: "Nováková",
    suffix: "Ph.D.",
    sex: "F",
  ),
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

= ÚVOD
Test titulní strany fakulty FVT.
