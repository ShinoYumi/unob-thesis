#import "/src/lib.typ": *
#set text(lang: "cs")

#show: thesis-with.with(
  draft: false,
  faculty: "fvl",
  programme: [Řízení a použití ozbrojených sil],
  specialisation: [Management informačních zdrojů],
  thesis: (
    type: "doctoral",
    title: [Persistent cover phase],
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
  acronyms: true,
  terms: true,
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
Normy #trm("iso") jsou v tomto testu použity záměrně.
