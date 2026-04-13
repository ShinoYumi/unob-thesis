#import "@preview/ez-today:1.1.0"
#import "../i18n/index.typ": t, thesis-type-is-bachelor-or-master, thesis-type-is-doctoral

// Styl: Vizuální parametry titulní strany.
// Poznámka: Pro ruční změnu vzhledu upravuj primárně tuto strukturu.
#let cover-vars = (
  page_height: 240mm,
  logo_height: 6.71cm,

  size_university: 16pt,
  size_faculty: 14pt,
  size_programme: 14pt,
  size_specialisation: 14pt,
  size_thesis_type: 24pt,
  size_title: 16pt,
  size_people: 14pt,
  size_city_year: 16pt,

  weight_faculty: "bold",
  weight_programme: "bold",
  weight_specialisation: "regular",
  weight_thesis_type: "bold",
  weight_title: "bold",

  header_row_1_height: 16pt,
  header_row_2_height: 14pt,
  header_row_3_height: 14pt,
  header_row_4_height: 14pt,
  people_row_height: 1.5em,

  gap_after_header: 24pt,
  gap_after_logo: 24pt,
  gap_after_thesis_type: 24pt,
  gap_after_title: 24pt,

  paragraph_leading: 1.5em,
)

// Funkce: cover-row
// Účel: Vykreslí jeden řádek s pevnou výškou.
#let cover-row(content, size: 14pt, weight: "regular", height: 14pt) = block(
  width: 100%,
  height: height,
  clip: false,
)[
  #align(center + horizon)[
    #set text(size: size, weight: weight)
    #content
  ]
]

// Funkce: cover-people-row
// Účel: Vykreslí řádek v bloku osob se stejnou výškou i při prázdném obsahu.
#let cover-people-row(content, vars) = block(
  width: 100%,
  height: vars.people_row_height,
  clip: false,
)[
  #set text(size: vars.size_people)
  #content
]

// Funkce: render-cover
// Účel: Vykreslí titulní stranu práce podle konfigurace školy, práce a osob.
#let render-cover(
  university,
  thesis,
  author,
  supervisor,
  first_advisor,
  second_advisor,
  has_value,
  has_person,
  format_name,
  get_faculty_name,
  get_logo_path,
  get_thesis_type_name,
  get_city_name,
  vars: cover-vars,
) = {
  show heading: none
  context heading(
    numbering: none,
    bookmarked: true,
    level: 1,
    outlined: false,
  )[ #t("title_page") ]

  set par(first-line-indent: 0mm)
  set page(footer: none)

  let faculty_line = if university.faculty != "uo" {
    upper(get_faculty_name(university.faculty))
  } else {
    []
  }
  let programme_line = if has_value(university.programme) {
    [#t("programme_label")#university.programme]
  } else {
    []
  }
  let specialisation_line = if has_value(university.specialisation) {
    [#t("specialisation_label")#university.specialisation]
  } else {
    []
  }

  // Pravidlo: Titulka je bez gridu s pevnou osnovou sekcí.
  block(width: 100%, height: vars.page_height)[
    #set par(first-line-indent: 0mm, leading: vars.paragraph_leading, justify: false)

    #align(center + top)[
      #cover-row(
        upper(t("university_name")),
        size: vars.size_university,
        height: vars.header_row_1_height,
      )
      #cover-row(
        faculty_line,
        size: vars.size_faculty,
        weight: vars.weight_faculty,
        height: vars.header_row_2_height,
      )
      #cover-row(
        programme_line,
        size: vars.size_programme,
        weight: vars.weight_programme,
        height: vars.header_row_3_height,
      )
      #cover-row(
        specialisation_line,
        size: vars.size_specialisation,
        weight: vars.weight_specialisation,
        height: vars.header_row_4_height,
      )
    ]

    #v(vars.gap_after_header)

    #align(center + horizon)[
      #image(get_logo_path(university.faculty), height: vars.logo_height, width: auto)
    ]

    #v(vars.gap_after_logo)

    #align(center + horizon)[
      #set text(size: vars.size_thesis_type, weight: vars.weight_thesis_type)
      #upper(get_thesis_type_name(thesis.type))
    ]

    #v(vars.gap_after_thesis_type)

    #align(center + horizon)[
      #set text(size: vars.size_title, weight: vars.weight_title)
      #thesis.title
    ]

    #v(vars.gap_after_title)

    #align(left + top)[
      #cover-people-row([
        #if author.sex != "F" { t("author_male") } else { t("author_female") }
        #format_name(author)
      ], vars)

      #cover-people-row(
        if has_person(supervisor) {
          context if thesis-type-is-bachelor-or-master(thesis.type) {
            [#t("supervisor_work_label")#format_name(supervisor)]
          } else {
            [#t("supervisor_label")#format_name(supervisor)]
          }
        } else {
          []
        },
        vars,
      )

      #cover-people-row(
        if has_person(first_advisor) {
          context if thesis-type-is-bachelor-or-master(thesis.type) {
            [#t("advisor_label")#format_name(first_advisor)]
          } else {
            [#t("co_supervisor_label")#format_name(first_advisor)]
          }
        } else {
          []
        },
        vars,
      )

      #if thesis-type-is-doctoral(thesis.type) {
        cover-people-row(
          if has_person(second_advisor) {
            [#t("co_supervisor_label")#format_name(second_advisor)]
          } else {
            []
          },
          vars,
        )
      }
    ]

    #place(bottom + center, scope: "parent", float: true)[
      #set text(size: vars.size_city_year)
      #upper(get_city_name(university.faculty))#ez-today.today(format: " Y")
    ]
  ]
}
