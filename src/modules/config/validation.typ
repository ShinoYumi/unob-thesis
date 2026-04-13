#import "../utils.typ": has-value, has-person
#import "../i18n/index.typ": t, is-supported-faculty, is-supported-thesis-type

// Funkce: panic-i18n
// Účel: Vyvolá chybu na základě i18n klíče.
#let panic-i18n(key) = context {
  panic(t(key))
}

// Funkce: validate-config
// Účel: Ověří vstupní konfiguraci šablony a při chybě vyvolá `panic`.
#let validate-config(
  draft,
  university,
  thesis,
  author,
  supervisor,
  declaration,
  assignment,
  outlines,
  acronyms,
  terms,
  guide,
  docs,
  submit_check,
) = {
  if type(draft) != bool {
    panic-i18n("error_draft_bool")
  }

  if not is-supported-faculty(university.faculty) {
    panic-i18n("error_unsupported_faculty")
  }

  if not is-supported-thesis-type(thesis.type) {
    panic-i18n("error_unsupported_thesis_type")
  }

  if not has-value(thesis.title) {
    panic-i18n("error_title_required")
  }

  if not has-person(author) {
    panic-i18n("error_author_required")
  }

  if declaration.declaration != false and not has-person(supervisor) {
    panic-i18n("error_supervisor_required_for_declaration")
  }

  if outlines.acronyms != false and type(acronyms) != dictionary {
    panic-i18n("error_outlines_acronyms_requires_dictionary")
  }

  if outlines.terms != false and type(terms) != dictionary {
    panic-i18n("error_outlines_terms_requires_dictionary")
  }

  if type(guide) != bool or type(docs) != bool {
    panic-i18n("error_guide_docs_bool")
  }

  if type(assignment.front) != bool or type(assignment.back) != bool {
    panic-i18n("error_assignment_bool")
  }

  if type(declaration.declaration) != bool or type(declaration.ai_used) != bool {
    panic-i18n("error_declaration_bool")
  }

  if type(submit_check) != bool {
    panic-i18n("error_submit_check_bool")
  }
}

// Funkce: validate-submit-check
// Účel: V přísném režimu ověří minimální náležitosti před odevzdáním.
#let validate-submit-check(
  submit_check,
  draft,
  supervisor,
  abstract,
  keywords,
  introduction,
) = {
  if submit_check != true {
    return
  }

  if draft == true {
    panic-i18n("error_submit_check_draft_disabled")
  }

  if not has-person(supervisor) {
    panic-i18n("error_submit_check_supervisor_required")
  }

  if not has-value(abstract.czech) {
    panic-i18n("error_submit_check_abstract_cs_required")
  }

  if not has-value(abstract.english) {
    panic-i18n("error_submit_check_abstract_en_required")
  }

  if not has-value(keywords.czech) {
    panic-i18n("error_submit_check_keywords_cs_required")
  }

  if not has-value(keywords.english) {
    panic-i18n("error_submit_check_keywords_en_required")
  }

  if not has-value(introduction) {
    panic-i18n("error_submit_check_introduction_required")
  }
}
