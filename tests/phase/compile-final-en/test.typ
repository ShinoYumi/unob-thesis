#import "/src/lib.typ": thesis-with, person
#set text(lang: "en")

#show: thesis-with.with(
  lang: "en",
  draft: false,
  faculty: "fvl",
  programme: [Military Leadership],
  specialisation: [Defence Management],
  thesis: (
    type: "master",
    title: [Compile final — English mode],
  ),
  author: person(
    prefix: "",
    name: "John",
    surname: "Smith",
    suffix: none,
    sex: "M",
  ),
  supervisor: person(
    prefix: "Col. Ing.",
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

= INTRODUCTION
This test verifies full final-mode compilation in English.
