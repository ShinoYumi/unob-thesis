#import "/src/lib.typ": thesis-with, person, trm, todo
#set text(lang: "en")

#show: thesis-with.with(
  draft: true,
  faculty: "fvl",
  thesis: (
    type: "master",
    title: [Compile draft EN],
  ),
  author: person(name: "John", surname: "Doe", sex: "M"),
  supervisor: person(name: "Jane", surname: "Doe", sex: "F"),
  assignment: false,
  acknowledgement: false,
  declaration: false,
  acronyms: true,
  terms: true,
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
We use #trm("iso", style: "first") and then #trm("iso").
#todo[Check the terminology consistency in this section.]
