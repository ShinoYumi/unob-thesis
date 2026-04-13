#import "../i18n/index.typ": t

// Funkce: render-lists
// Účel: Vykreslí obsah a volitelné seznamy (zkratky, pojmy, obrázky, tabulky, rovnice, výpisy).
#let render-lists(
  outlines,
  acronyms,
  terms,
  has_used_acronyms,
  has_used_terms,
  generate_acronyms_list,
  generate_terms_list,
) = {
  set page(footer: context {
    set align(center)
    counter(page).display("1")
  })

  if outlines.headings != false {
    show outline.entry.where(level: 1): it => {
      set text(size: 14pt, weight: "bold")
      upper(it)
    }
    show outline.entry.where(level: 2): it => {
      set text(size: 13pt)
      it
    }
    show outline.entry.where(level: 3): it => {
      set text(size: 12pt, style: "italic")
      it
    }

    outline(
      target: heading.where(supplement: [heading]),
      indent: 1em,
      depth: 3,
      title: t("toc"),
    )
  }

  // Zkratky a pojmy mají speciální logiku (has_used_*), zůstávají explicitní.
  context if outlines.acronyms != false and has_used_acronyms(acronyms) {
    heading(bookmarked: true, outlined: true, numbering: none, level: 1)[
      #t("list_acronyms")
    ]
    generate_acronyms_list(acronyms)
  }

  context if outlines.terms != false and has_used_terms(terms) {
    heading(bookmarked: true, outlined: true, numbering: none, level: 1)[
      #t("list_terms")
    ]
    generate_terms_list(terms)
  }

  // Zbývající seznamy sdílí identickou strukturu — generovány z dat.
  let _outline_sections = (
    ("figures",   "list_figures",   figure.where(kind: image), false),
    ("tables",    "list_tables",    figure.where(kind: table), true),
    ("equations", "list_equations", math.equation,             true),
    ("listings",  "list_listings",  figure.where(kind: raw),   true),
  )
  for (key, label, target, bookmarked) in _outline_sections {
    context if outlines.at(key) != false {
      heading(bookmarked: bookmarked, outlined: true, numbering: none, level: 1)[
        #t(label)
      ]
      outline(title: none, target: target)
    }
  }
}
