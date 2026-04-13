#import "@preview/ez-today:1.1.0"
#import "../i18n/index.typ": t, thesis-type-is-bachelor-or-master

// Funkce: render-assignment
// Účel: Vloží sken zadání práce (front/back) a související oddíl.
#let render-assignment(assignment) = {
  let has_assignment_front = assignment.front != false
  let has_assignment_back = assignment.back != false

  context if has_assignment_front or has_assignment_back {
    {
      show heading: none
      heading(numbering: none, bookmarked: true, outlined: false, level: 1)[
        #t("assignment")
      ]
      pagebreak(to: "odd")
    }
  }

  if has_assignment_front {
    box(image("../../../template/front.png", width: 100%), inset: -2.5cm)
  }
  if has_assignment_back {
    box(image("../../../template/back.png", width: 100%), inset: -2.5cm)
  }
}

// Funkce: render-acknowledgement
// Účel: Vykreslí poděkování nebo výchozí vzorový text.
#let render-acknowledgement(acknowledgement, has_value) = {
  context if acknowledgement != false {
    heading(
      t("acknowledgement"),
      numbering: none,
      bookmarked: true,
      level: 1,
    )

    if has_value(acknowledgement) {
      acknowledgement
    } else if text.lang == "en" {
      [Acknowledgement text \ Acknowledgements are not a mandatory part of the thesis. It is appropriate to express gratitude to parents, the thesis supervisor, consultants, or anyone who helped or supported you during the work or your studies.]
    } else {
      [Text poděkování \ Poděkování není povinnou součástí závěrečné práce. Je vhodné vyjádřit poděkování rodičům, vedoucímu závěrečné práce, konzultantům či osobám, které Vám pomohly / byly nápomocny při zpracování závěrečné práce nebo v průběhu studia.]
    }
  }
}

// Funkce: _gendered
// Účel: Vrátí `male_form` nebo `female_form` podle pohlaví autora.
#let _gendered(sex, male_form, female_form) = if sex == "M" { male_form } else { female_form }

// Funkce: render-declaration
// Účel: Vykreslí čestné prohlášení vždy v českém jazyce.
#let render-declaration(
  declaration,
  author,
  supervisor,
  university,
  thesis,
  format_supervisor_for_declaration,
  format_name,
  get_thesis_type_name,
  get_faculty_name,
  get_city_name,
) = {
  context if declaration.declaration != false {
    heading(
      [ČESTNÉ PROHLÁŠENÍ],
      numbering: none,
      bookmarked: true,
      level: 1,
    )

    [
      Prohlašuji, že jsem zadanou #text(lang: "cs")[#get_thesis_type_name(thesis.type, variant: 3)]
      na téma #emph[#thesis.title] #lower[vypracoval] samostatně, pod odborným vedením
      #if thesis-type-is-bachelor-or-master(thesis.type) {
        if supervisor.sex == "M" { [vedoucího práce] } else { [vedoucí práce] }
      } else {
        if supervisor.sex == "M" { [školitele] } else { [školitelky] }
      }
      #format_supervisor_for_declaration(supervisor) a
      #_gendered(author.sex, [použil], [použila]) jsem pouze literární zdroje uvedené v práci.

      #parbreak()

      Dále prohlašuji, že při vytváření této práce jsem
      #if declaration.ai_used != false {
        _gendered(author.sex, [použil], [použila])
        [
          nástroje umělé inteligence. Tyto nástroje byly využity v souladu s platnými obecně závaznými právními předpisy, vnitřními předpisy
          Univerzity obrany a #text(lang: "cs")[#get_faculty_name(university.faculty, variant: 2)]
          a etickými normami. Veškeré výsledky, které byly generovány nebo
          ovlivněny nástroji umělé inteligence, jsou v této práci
          identifikovány, popsány a podloženy relevantními informacemi o
          použitých algoritmech, tréninkových datech a metodologii.
        ]
      } else {
        _gendered(author.sex, [nepoužil], [nepoužila])
        [ nástroje umělé inteligence. ]
      }

      #parbreak()

      Dále prohlašuji, že jsem
      #_gendered(author.sex, [seznámen], [seznámena])
      s tím, že se na moji #text(lang: "cs")[#get_thesis_type_name(thesis.type, variant: 3)]
      vztahují práva
      a povinnosti vyplývající ze zákona č. 121/2000 Sb., o právu autorském,
      o právech souvisejících s právem autorským a o změně některých zákonů
      (autorský zákon), ve znění pozdějších předpisů, zejména skutečnosti,
      že Univerzita obrany má právo na uzavření licenční smlouvy o užití
      této #text(lang: "cs")[#get_thesis_type_name(thesis.type, variant: 2)]
      jako školního díla
      podle §~60~odst.~1 výše uvedeného zákona, a s tím, že pokud dojde k
      užití této #text(lang: "cs")[#get_thesis_type_name(thesis.type, variant: 2)]
      mnou nebo
      bude poskytnuta licence o užití díla třetímu subjektu, je Univerzita
      obrany oprávněna ode mne požadovat přiměřený příspěvek na úhradu
      nákladů, které na vytvoření díla vynaložila, a to podle okolností až
      do jejich skutečné výše.

      #parbreak()

      Souhlasím se zpřístupněním své
      #text(lang: "cs")[#get_thesis_type_name(thesis.type, variant: 2)]
      pro prezenční studium v prostorách knihovny Univerzity obrany.

      #v(2cm)
      #align(center, grid(
        align: (left, center),
        columns: (50%, 50%),
        rows: 2,
        [
          V #get_city_name(university.faculty, variant: 2),
          dne #lower[#ez-today.today(lang: "cs", format: "d. m. Y")]
        ],
        [#box(width: 1fr, repeat[.])],

        v(.5cm), [],
        [], [#format_name(author)],
      ))
    ]
  }
}

// Funkce: _render_one_abstract
// Účel: Vykreslí jeden jazykový blok abstraktu s nadpisem a klíčovými slovy.
#let _render_one_abstract(heading_text, keyword_label, content, keywords, placeholder, keywords_placeholder: []) = {
  heading(numbering: none, bookmarked: true, level: 1)[#heading_text]
  if content != [] {
    content
    parbreak()
    h(-7mm) + [*#keyword_label*: ] + keywords
  } else {
    placeholder
    parbreak()
    h(-7mm) + [*#keyword_label*: ] + keywords_placeholder
  }
}

// Funkce: render-abstracts
// Účel: Vykreslí český a anglický abstrakt včetně klíčových slov.
#let render-abstracts(abstract, keywords) = {
  _render_one_abstract(
    [ABSTRAKT],
    [Klíčová slova],
    abstract.czech,
    keywords.czech,
    [Abstrakt představuje stručnou a přesnou charakteristiku obsahu závěrečné práce, poskytuje informace o problému, způsobu řešení a dosažených výsledcích práce. Rozsah abstraktu v českém jazyce do jedné #footnote[Jako pomocník pro vypracování možné využít: ČSN ISO 214 Dokumentace – abstrakty pro publikace a dokumentaci, případně: https://www.herout.net/blog/2013/12/jak-psat-abstrakt]strany.],
    keywords_placeholder: [ uvádí se 5–10 klíčových slov (= hesla, sousloví a fráze) v abecedním pořadí, které charakterizují obsahovou podstatu závěrečné práce],
  )

  _render_one_abstract(
    [ABSTRACT],
    [Keywords],
    abstract.english,
    keywords.english,
    [Text abstraktu v anglickém jazyce.],
  )
}

// Funkce: render-introduction
// Účel: Vykreslí úvod nebo výchozí vzorový text úvodu.
#let render-introduction(introduction) = {
  context if introduction != [] {
    [#metadata(true) <unob-running-header-start>]
    heading(level: 1, outlined: true, numbering: none)[#t("introduction")]
    introduction
  } else {
    context [#metadata(true) <unob-running-header-start>
      #heading(level: 1, outlined: true, numbering: none)[#t("introduction")]
      #if text.lang == "en" [
        The introduction expresses the topicality, significance and necessity of the problem being addressed from a theoretical or practical perspective. The introduction does not contain the thesis objective, methods, or a summary of the chapters — these belong in their own dedicated sections. Recommended length: 1–2 pages.
      ] else [
        Úvod vyjadřuje aktuálnost, významnost a potřebnost řešeného problému z hlediska teorie či praxe. V úvodu se nepíše cíl práce, použité metody ani obsah práce. K tomuto účelu slouží samostatné kapitoly závěrečné práce. Doporučený rozsah úvodu je 1–2 normostrany.
      ]]
  }
}
