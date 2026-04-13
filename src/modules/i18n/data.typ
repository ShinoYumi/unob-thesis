// Data: Překlady řetězců a statické tabulky pro i18n moduly.
#let translations = (
  "title_page": (cs: [TITULNÍ LIST], en: [TITLE PAGE]),
  "assignment": (cs: [ZADÁNÍ PRÁCE], en: [ASSIGNMENT]),
  "acknowledgement": (cs: [PODĚKOVÁNÍ], en: [ACKNOWLEDGEMENT]),
  "declaration": (cs: [ČESTNÉ PROHLÁŠENÍ], en: [DECLARATION]),
  "toc": (cs: [OBSAH], en: [TABLE OF CONTENTS]),
  "list_acronyms": (cs: [SEZNAM ZKRATEK], en: [LIST OF ACRONYMS]),
  "list_terms": (cs: [SEZNAM POJMŮ], en: [LIST OF TERMS]),
  "list_figures": (cs: [SEZNAM OBRÁZKŮ], en: [LIST OF FIGURES]),
  "list_tables": (cs: [SEZNAM TABULEK], en: [LIST OF TABLES]),
  "list_equations": (cs: [SEZNAM ROVNIC], en: [LIST OF EQUATIONS]),
  "list_listings": (cs: [SEZNAM VÝPISŮ], en: [LIST OF LISTINGS]),
  "introduction": (cs: [ÚVOD], en: [INTRODUCTION]),
  "conclusion": (cs: [ZÁVĚR], en: [CONCLUSION]),
  "list_annexes": (cs: [SEZNAM PŘÍLOH], en: [LIST OF ANNEXES]),
  "annex": (cs: [PŘÍLOHA], en: [ANNEX]),
  "university_name": (cs: [Univerzita obrany], en: [University of Defence]),
  "programme_label": (cs: [Studijní program: ], en: [Programme: ]),
  "specialisation_label": (cs: [Studijní specializace: ], en: [Specialisation: ]),
  "author_male": (cs: [Zpracoval:], en: [Author:]),
  "author_female": (cs: [Zpracovala:], en: [Author:]),
  "supervisor_work_label": (cs: [Vedoucí práce:], en: [Supervisor:]),
  "supervisor_label": (cs: [Školitel:], en: [Supervisor:]),
  "advisor_label": (cs: [Odborný konzultant:], en: [Advisor:]),
  "co_supervisor_label": (cs: [Školitel-specialista:], en: [Co-Supervisor:]),
  "bibliography_title": (cs: [SEZNAM POUŽITÝCH ZDROJŮ], en: [BIBLIOGRAPHY]),
  "invalid_mode": (
    cs: "Neplatná hodnota `draft`. Použijte `true` nebo `false`.",
    en: "Invalid `draft` value. Use `true` or `false`."
  ),
  "error_draft_bool": (
    cs: "Parametr `draft` musí být typu bool (`true` nebo `false`).",
    en: "`draft` must be a bool (`true` or `false`).",
  ),
  "error_title_required": (
    cs: "Parametr `thesis.title` nesmí být prázdný.",
    en: "`thesis.title` must not be empty.",
  ),
  "error_author_required": (
    cs: "Autor musí mít vyplněné alespoň jméno nebo příjmení.",
    en: "Author must have at least a name or surname.",
  ),
  "error_supervisor_required_for_declaration": (
    cs: "Při zapnutém prohlášení je nutné vyplnit vedoucího/školitele.",
    en: "When declaration is enabled, supervisor must be provided.",
  ),
  "error_outlines_acronyms_requires_dictionary": (
    cs: "Pro seznam zkratek (`outlines.acronyms`) musí být `acronyms` slovník.",
    en: "For acronym list (`outlines.acronyms`), `acronyms` must be a dictionary.",
  ),
  "error_outlines_terms_requires_dictionary": (
    cs: "Pro glosář pojmů (`outlines.terms`) musí být `terms` slovník.",
    en: "For glossary of terms (`outlines.terms`), `terms` must be a dictionary.",
  ),
  "error_guide_docs_bool": (
    cs: "`guide` a `docs` musí být typu bool.",
    en: "`guide` and `docs` must be bool.",
  ),
  "error_assignment_bool": (
    cs: "`assignment.front` a `assignment.back` musí být typu bool.",
    en: "`assignment.front` and `assignment.back` must be bool.",
  ),
  "error_declaration_bool": (
    cs: "Hodnoty v `declaration` musí být typu bool.",
    en: "`declaration` values must be bool.",
  ),
  "error_submit_check_bool": (
    cs: "`lists.submit_check` musí být typu bool.",
    en: "`lists.submit_check` must be bool.",
  ),
  "error_submit_check_draft_disabled": (
    cs: "Při `lists.submit_check: true` musí být `draft: false`.",
    en: "With `lists.submit_check: true`, `draft` must be `false`.",
  ),
  "error_submit_check_supervisor_required": (
    cs: "Při `lists.submit_check: true` musí být vyplněn vedoucí/školitel.",
    en: "With `lists.submit_check: true`, supervisor must be provided.",
  ),
  "error_submit_check_abstract_cs_required": (
    cs: "Při `lists.submit_check: true` musí být vyplněn český abstrakt (`abstract.czech`).",
    en: "With `lists.submit_check: true`, Czech abstract (`abstract.czech`) is required.",
  ),
  "error_submit_check_abstract_en_required": (
    cs: "Při `lists.submit_check: true` musí být vyplněn anglický abstrakt (`abstract.english`).",
    en: "With `lists.submit_check: true`, English abstract (`abstract.english`) is required.",
  ),
  "error_submit_check_keywords_cs_required": (
    cs: "Při `lists.submit_check: true` musí být vyplněna česká klíčová slova (`keywords.czech`).",
    en: "With `lists.submit_check: true`, Czech keywords (`keywords.czech`) are required.",
  ),
  "error_submit_check_keywords_en_required": (
    cs: "Při `lists.submit_check: true` musí být vyplněna anglická klíčová slova (`keywords.english`).",
    en: "With `lists.submit_check: true`, English keywords (`keywords.english`) are required.",
  ),
  "error_submit_check_introduction_required": (
    cs: "Při `lists.submit_check: true` musí být vyplněn `introduction`.",
    en: "With `lists.submit_check: true`, `introduction` must be provided.",
  ),
  "note_warning":        (cs: [Omezení a rizika],    en: [Limitations and Risks]),
  "note_solution":       (cs: [Doporučený postup],   en: [Recommended Approach]),
  "note_idea":           (cs: [Klíčová myšlenka],    en: [Key Idea]),
  "note_todo":           (cs: [TODO],                en: [TODO]),
  "note_definition":     (cs: [Definice],             en: [Definition]),
  "note_context":        (cs: [Kontext],              en: [Context]),
  "note_example":        (cs: [Příklad],              en: [Example]),
  "note_method":         (cs: [Metodická poznámka],  en: [Methodological Note]),
  "note_interpretation": (cs: [Interpretace],         en: [Interpretation]),
  "note_summary":        (cs: [Shrnutí],              en: [Summary]),
  "note_literature":     (cs: [Zdroje literatury],   en: [Literature Reference]),
  "error_unsupported_faculty": (
    cs: "Nepodporovaná fakulta! Zvolte: `fvl` | `fvt` | `vlf` | `uo`",
    en: "Unsupported faculty! Try: `fvl` | `fvt` | `vlf` | `uo`",
  ),
  "error_unsupported_faculty_variant": (
    cs: "Nepodporovaná varianta fakulty! Zvolte: `1` | `2`",
    en: "Unsupported faculty variant! Try: `1` | `2`",
  ),
  "error_unsupported_city_variant": (
    cs: "Nepodporovaná varianta města! Zvolte: `1` | `2`",
    en: "Unsupported city variant! Try: `1` | `2`",
  ),
  "error_thesis_type_must_be_string": (
    cs: "Typ práce musí být řetězec.",
    en: "Thesis type must be a string.",
  ),
  "error_unsupported_thesis_type": (
    cs: "Nepodporovaný typ práce! Použijte `bachelor` | `master` | `doctoral`.",
    en: "Unsupported thesis type! Use `bachelor` | `master` | `doctoral`.",
  ),
  "error_unsupported_thesis_type_variant": (
    cs: "Nepodporovaná varianta typu práce! Zvolte: `1` | `2` | `3`",
    en: "Unsupported thesis type variant! Try: `1` | `2` | `3`",
  ),
)

// Konstanty: Podporované výčtové hodnoty používané napříč moduly.
#let supported_faculties = ("fvl", "fvt", "vlf", "uo")
#let supported_thesis_types = ("bachelor", "master", "doctoral")

#let faculty_names = (
  "fvl": (
    cs: ([Fakulta vojenského leadershipu], [Fakulty vojenského leadershipu]),
    en: ([Faculty of Military Leadership], [Faculty of Military Leadership]),
  ),
  "fvt": (
    cs: ([Fakulta vojenských technologií], [Fakulty vojenských technologií]),
    en: ([Faculty of Military Technology], [Faculty of Military Technology]),
  ),
  "vlf": (
    cs: ([Vojenská lékařská fakulta], [Vojenské lékařské fakulty]),
    en: ([Military Faculty of Medicine], [Military Faculty of Medicine]),
  ),
  "uo": (
    cs: ([], []),
    en: ([], []),
  ),
)

#let city_names = (
  "fvl": ([BRNO], [Brně]),
  "fvt": ([BRNO], [Brně]),
  "uo": ([BRNO], [Brně]),
  "vlf": ([HRADEC KRÁLOVÉ], [Hradci Králové]),
)

#let thesis_type_forms = (
  "bachelor": (
    cs: ([Bakalářská práce], [bakalářské práce], [bakalářskou práci]),
    en: ([Bachelor Thesis], [bachelor thesis], [bachelor thesis]),
  ),
  "master": (
    cs: ([Diplomová práce], [diplomové práce], [diplomovou práci]),
    en: ([Master Thesis], [master thesis], [master thesis]),
  ),
  "doctoral": (
    cs: ([Disertační práce], [disertační práce], [disertační práci]),
    en: ([Dissertation], [dissertation], [dissertation]),
  ),
)
