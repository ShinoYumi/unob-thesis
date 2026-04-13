#import "/src/lib.typ": *
#set text(lang: "cs")

#show: thesis-with.with(
  draft: false,
  faculty: "fvl",
  programme: [],
  specialisation: [],
  thesis: (
    type: "doctoral",
    title: [Persistent cover without programme],
  ),
  author: person(
    prefix: "rtm.",
    name: "Jan",
    surname: "Novák",
    suffix: none,
    sex: "M",
  ),
  supervisor: person(
    prefix: "pplk. Ing.",
    name: "Jana",
    surname: "Nováková",
    suffix: "Ph.D.",
    sex: "F",
  ),
  first_advisor: person(prefix: "Mgr.", name: "Petr", surname: "Svoboda"),
  second_advisor: person(prefix: "Ing.", name: "František", surname: "Dvořák"),
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
Kontrolní text pro stabilitu titulní strany bez programu a specializace.
