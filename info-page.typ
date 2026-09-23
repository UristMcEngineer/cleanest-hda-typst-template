#import "confidentiality-statement.typ": *
#import "declaration-of-authorship.typ": *

#let info-page(
  authors,
  title,
  date,
  date-format,
  pdf-version,
  show-confidentiality-statement-at-beginning,
  show-declaration-of-authorship-at-beginning,
  confidentiality-statement-content,
  declaration-of-authorship-content,
  university,
  university-location,
  at-university,
  language,
  many-authors,
  page-margin,
  edition,
) = {

  // ---------- Page Setup ---------------------------------------

  set page(
    margin: page-margin,
  )

  let copyright-notice = {
    for author in authors {
      text(size: 11pt, [#author.name: #text(style: "italic",title), © #date.display(date-format)])
      linebreak()
    }
  }

  // In print, the declaration/confidentiality page gets hand-signed, so the copyright
  // line moves to its own page ahead of it instead of sharing that page's bottom margin.
  // That page carries no heading of its own, so it reuses the running header's existing
  // suppression flag (also used for two-sided layouts' blank inserted pages) to stay bare.
  if (edition == "print") {
    place(bottom + left, copyright-notice)
    pagebreak()
    state("is-padding-page", false).update(false)
  }

  if (show-declaration-of-authorship-at-beginning) {

    declaration-of-authorship(
      authors,
      title,
      declaration-of-authorship-content,
      date,
      language,
      many-authors,
      at-university,
      university-location,
      date-format,
      edition,
    )
  }

  if (show-confidentiality-statement-at-beginning) {

    if (show-declaration-of-authorship-at-beginning) {
      pagebreak()
    }

    confidentiality-statement(
      authors,
      title,
      confidentiality-statement-content,
      university,
      university-location,
      date,
      language,
      many-authors,
      date-format,
  )
  }

  // ---------- Info at Bottom of Page ---------------------------------------

  if (edition != "print") {
    place(bottom + left, copyright-notice)
  }
}
