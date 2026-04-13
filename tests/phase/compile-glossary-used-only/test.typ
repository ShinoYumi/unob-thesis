#import "/src/lib.typ": *
#set text(lang: "cs")

#show: thesis-with.with(
  draft: false,
  faculty: "fvl",
  thesis: (
    type: "master",
    title: [Compile glossary used only],
  ),
  author: person(name: "Jan", surname: "Novák", sex: "M"),
  supervisor: person(name: "Jana", surname: "Nováková", sex: "F"),
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

#context {
  assert.eq(query(selector(label("__unob_acronym_list_iso"))).len() > 0, true)
  assert.eq(query(selector(label("__unob_acronym_list_acr"))).len(), 0)
}

= ÚVOD
#trm("iso") je použitá zkratka.
#trm("zero_trust") je použitý pojem bez zkratky.
