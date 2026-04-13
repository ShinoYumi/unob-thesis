#import "../i18n/index.typ": t
#import "../utils.typ": is-draft-mode

// Formát číslování stránek a figur v přílohách (A–1, A–2, …).
#let _annex_num_fmt = "A\u{2013}1"

// Funkce: annex
// Účel: Přepne sazbu do režimu příloh a vygeneruje seznam příloh.
#let annex(show_outline: true, draft: auto, body) = context {
  let is_draft = is-draft-mode(draft: draft)

  if is_draft {
    // Pravidlo: Draft zachová plynulý tok textu bez přepnutí sazby příloh.
    body
  } else {
    // Pravidlo: Seznam příloh začíná vždy na nové stránce.
    pagebreak()

    // Pravidlo: V režimu příloh mají H1 tvar `PŘÍLOHA A ...`.
    show heading.where(level: 1): set heading(
      numbering: "A",
      supplement: t("annex"),
    )

    // Pravidlo: Nadpis seznamu příloh není číslovaný.
    set align(left)
    block(width: 100%)[
      #set text(size: 14pt, weight: "bold")
      #set par(first-line-indent: 0mm)
      #upper(t("list_annexes"))
      #v(.75em)
    ]

    if show_outline != false {
      // Pravidlo: Seznam příloh obsahuje jen přílohové H1 (žádné kapitoly hlavního textu).
      show outline.entry: it => [
        #if it.prefix() != none {
          h(-7mm)+upper(strong([#t("annex") #it.prefix() #it.body()]))
        } else {
          h(-7mm)+upper(strong(it.body()))
        }
      ]
      outline(
        target: heading.where(level: 1, supplement: t("annex")),
        title: none,
        depth: 1,
      )
    }

    show heading.where(level: 1): it => {
      pagebreak()
      counter(page).update(1)
      block(width: 100%)[
        #set text(size: 14pt, weight: "bold")
        #set par(first-line-indent: 0mm)
        #it.supplement
        #{
          if it.numbering != none {
            numbering(it.numbering, ..counter(heading).at(it.location()))
          }
        }
        #upper(it.body)
        #counter(figure.where(kind: table)).update(0)
        #counter(figure.where(kind: image)).update(0)
        #counter(math.equation).update(0)
      ]
    }

    set page(
      numbering: n => numbering(
        _annex_num_fmt,
        counter(heading).get().first(),
        n,
      ),
      footer: context {
        set align(center)
        counter(page).display(page.numbering)
      },
    )

    counter(page).update(1)
    counter(heading).update(0)
    set heading(numbering: "A")

    set figure(numbering: n => numbering(
      _annex_num_fmt,
      counter(heading).get().first(),
      n,
    ))

    show figure.where(kind: image): set figure(outlined: false)
    show figure.where(kind: table): set figure(outlined: false)
    show figure.where(kind: math.equation): set figure(outlined: false)
    show figure.where(kind: raw): set figure(outlined: false)

    show heading.where(level: 2): set heading(numbering: none, outlined: false)
    show heading.where(level: 3): set heading(numbering: none, outlined: false)
    show heading.where(level: 4): set heading(numbering: none, outlined: false)

    body
  }
}
