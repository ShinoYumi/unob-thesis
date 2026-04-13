#import "@preview/vlna:0.1.1": apply-vlna
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

// Stav: Běžící záhlaví (aktuální kapitola + podkapitola).
#let running-header-state = state(
  "unob-running-header",
  (
    chapter: [],
    subchapter: [],
  ),
)

// Funkce: heading-mark
// Účel: Sestaví text značky záhlaví ve tvaru `číslo název`.
#let heading-mark(it) = {
  let number = if it.numbering != none {
    numbering(it.numbering, ..counter(heading).at(it.location()))
  } else {
    none
  }

  if number == none {
    it.body
  } else {
    [#number #it.body]
  }
}

// Funkce: render-running-header
// Účel: Vykreslí běžící záhlaví ve formátu kapitola | podkapitola.
#let render-running-header() = context {
  let started = query(selector(<unob-running-header-start>).before(here())).len() > 0
  let ended = query(selector(<unob-running-header-end>).before(here())).len() > 0

  if started and not ended {
    let current = running-header-state.get()
    let chapter = current.at("chapter", default: [])
    let subchapter = current.at("subchapter", default: [])

    block(width: 100%, inset: (bottom: 4mm))[
      #set text(size: 9pt)
      #set par(first-line-indent: 0mm)
      #grid(
        columns: (1fr, 1fr),
        align: (left, right),
        [#chapter],
        [#if subchapter != [] { subchapter }],
      )
    ]
  } else {
    []
  }
}

// Funkce: apply-base-styles
// Účel: Nastaví globální sazbu dokumentu (text, stránka, rovnice, odkazy).
#let apply-base-styles(
  body,
  draft: false,
  author: (),
  thesis: (),
  abstract: (),
  keywords: (),
  theme: (),
) = {
  let links_colored   = theme.at("links_colored",   default: false)
  let faculty_colored = theme.at("faculty_colored", default: false)
  let link_color = if not links_colored {
    rgb("#000000")
  } else if theme.at("link_color", default: none) != none {
    theme.at("link_color")
  } else if faculty_colored and theme.at("faculty_color", default: none) != none {
    theme.at("faculty_color")
  } else {
    rgb("#000000")
  }
  show link: set text(fill: link_color)

  if draft != true {
    show: codly-init.with()
    codly(languages: codly-languages)
    show: apply-vlna

    // Pravidlo: Při `draft: false` přidá kompenzaci proti vdovám a sirotkům.
    show par: it => {
      let threshold = 10%
      block(breakable: false, height: threshold)
      v(-threshold, weak: true)
      it
    }
  }

  let keywords_cs = if type(keywords.czech) == str {
    keywords.czech.trim()
  } else {
    ""
  }
  let keywords_en = if type(keywords.english) == str {
    keywords.english.trim()
  } else {
    ""
  }
  let combined_keywords = if keywords_cs.len() > 0 and keywords_en.len() > 0 {
    keywords_cs + ", " + keywords_en
  } else if keywords_cs.len() > 0 {
    keywords_cs
  } else {
    keywords_en
  }

  set document(
    author: author.prefix
      + " "
      + author.name
      + " "
      + author.surname
      + " "
      + author.suffix,
    title: thesis.title,
    date: auto,
    description: abstract.czech,
    keywords: combined_keywords,
  )

  set text(
    bottom-edge: "bounds",
    size: 12pt,
    overhang: true,
    font: "TeX Gyre Termes",
    fallback: true,
    hyphenate: true,
    costs: if draft != true {
      (runt: 1000%, hyphenation: 1000%, widow: 1000%, orphan: 1000%)
    } else {
      (runt: 100%, hyphenation: 100%, widow: 100%, orphan: 100%)
    },
  )

  show math.equation: set text(font: "TeX Gyre Termes Math", fallback: true)
  show raw: set text(font: "TeX Gyre Cursor", fallback: true)

  set page(
    margin: if draft != true {
      (inside: 35mm, outside: 25mm, y: 25mm)
    } else {
      (left: 10mm, right: 50mm, top: 10mm, bottom: 10mm)
    },
    header: none,
    numbering: "1",
    footer: context {
      set align(center)
      counter(page).display(page.numbering)
    },
    paper: "a4",
    binding: auto,
  )

  set par(
    first-line-indent: (amount: 7mm, all: true),
    linebreaks: if draft != true { "optimized" } else { "simple" },
    leading: 1.05em,
    justify: true,
  )

  set enum(indent: 1em)
  set list(indent: 1em)

  set math.equation(numbering: (..nums) => {
    let section = counter(heading).get().first()
    let safe_section = if section == none { 1 } else { section }
    numbering("(1.1)", safe_section, ..nums)
  })

  body
}

// Funkce: apply-heading-styles
// Účel: Nastaví číslování, vzhled a zalamování nadpisů.
#let apply-heading-styles(body, draft: false) = {
  set page(footer: none)
  set heading(numbering: "1.1.1", supplement: [heading], depth: 3)

  show heading.where(level: 1): it => {
    running-header-state.update((
      chapter: heading-mark(it),
      subchapter: [],
    ))

    if draft != true {
      pagebreak()
    }
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: image)).update(0)
    counter(math.equation).update(0)

    block(width: 100%)[
      #set text(size: 14pt, weight: "bold")
      #set par(first-line-indent: 0mm)
      #upper(it)
      #v(1em)
    ]
  }

  // Helper: level 2 a 3 se liší pouze velikostí textu.
  let _subheading_rule(size) = it => {
    running-header-state.update(prev => (
      chapter: prev.at("chapter", default: []),
      subchapter: heading-mark(it),
    ))
    block(width: 100%)[
      #set text(size: size, weight: "bold")
      #v(.5em)
      #it
      #v(.5em)
    ]
  }
  show heading.where(level: 2): _subheading_rule(14pt)
  show heading.where(level: 3): _subheading_rule(13pt)

  show heading.where(level: 4): it => block(width: 100%)[
    #set text(size: 12pt, weight: "bold")
    #v(.5em)
    #it
    #v(.5em)
  ]
  show heading.where(level: 4): set heading(numbering: none)

  body
}

// Funkce: apply-figure-styles
// Účel: Nastaví vzhled popisků a číslování obrázků, tabulek a rovnic.
#let apply-figure-styles(body) = {
  set figure.caption(separator: " ")
  show figure.caption: it => [
    #v(1em)
    #it.supplement #context it.counter.display(it.numbering)~#it.body
    #v(1em)
  ]

  let figure_spacing = 1em
  show figure: it => {
    let content = block(width: 100%, inset: (y: figure_spacing), align(
      center,
      it,
    ))
    if it.placement == none {
      block(it, inset: (y: figure_spacing))
    } else {
      place(it.placement, float: true, content)
    }
  }
  show figure: set block(breakable: true, spacing: 1.2em)
  show figure: align.with(center)

  show table.cell.where(y: 0): strong
  set table(stroke: 0.7pt)
  show figure.where(kind: table): set figure.caption(
    position: top,
    separator: [],
  )
  show figure.where(kind: raw): set figure.caption(position: top, separator: [])
  show figure.where(kind: math.equation): set figure.caption(
    position: top,
    separator: [],
  )

  show math.equation.where(block: true): it => {
    v(.5em)
    it
    v(.5em)
  }

  show table: set text(size: 10pt, hyphenate: true)
  show table: set par(justify: true)
  set table.hline(stroke: .5pt)

  set figure(numbering: n => numbering(
    "1.1 ",
    counter(heading).get().first(),
    n,
  ))

  body
}
