#import "locale.typ": *

// KOMA's `\Large`, `\LARGE` and `\huge` steps at an 11pt base document class. Those steps are table-driven rather than a fixed fraction of the base size, so they are spelled out instead of being scaled from `body-size`.
#let SIZE-LARGE = 14.4pt
#let SIZE-XLARGE = 17.28pt
#let SIZE-HUGE = 20.74pt

// Vertical gaps inside the title page's blocks: between the university and its faculty, between a title and its subtitle, between the "for the degree of" phrase and the degree itself, and between the "submitted by" phrase, the author name(s) and the student id. See the note on `v()` in `titlepage` for why these are not the LaTeX template's `\vspace` arguments verbatim.
#let FACULTY-GAP = 0.8cm
#let SUBTITLE-GAP = 0.65cm
#let DEGREE-GAP = 0.65cm
#let AUTHOR-GAP = 0.6cm

#let titlepage(
  authors,
  title-font,
  language,
  logo-left,
  logo-right,
  many-authors,
  supervisor,
  title,
  subtitle,
  type-of-thesis,
  university,
  faculty,
  at-university,
  show-confidentiality-statement,
  confidentiality-marker,
  body-size,
  titlepage-margin,
) = {

  // ---------- Page Setup ---------------------------------------

  // The title page carries its own margins instead of the body's: its text block is wider and sits centered on the physical page, where the body block is narrower and shifted towards the binding edge. `titlepage-margin` is computed alongside `page-margin` in `lib.typ`.
  set page(margin: titlepage-margin)
  // The whole page in `title-font`, all elements centered
  set text(font: title-font, size: body-size)
  // Every vertical gap on this page is an explicit `v()`, so the implicit spacing Typst puts between paragraphs and blocks -- which scales with the surrounding font size and would add itself on top of those values -- is switched off.
  //
  // The gap constants above are chosen to reproduce the gaps the LaTeX template produces, not copied from its `\vspace` arguments: LaTeX advances to the next line by a full baselineskip before adding its `\vspace`, where stacked Typst blocks advance only by the line's own height.
  set par(justify: false, spacing: 0pt)
  set block(spacing: 0pt)
  set align(center)

  // ---------- Logo(s) ---------------------------------------
  //
  // A single logo spans the full width of the title page's text block; a left/right pair splits that width between them, each keeping its own aspect ratio.

  if logo-left != none and logo-right == none {
    block(width: 100%, logo-left)
  } else if logo-left != none and logo-right != none {
    grid(
      columns: (1fr, 1fr),
      column-gutter: 1em,
      align: (left + horizon, right + horizon),
      logo-left,
      logo-right,
    )
  }

  // ---------- University / Faculty ---------------------------------------

  v(1fr)

  text(weight: "bold", size: SIZE-HUGE, university)
  if faculty != none and faculty != "" {
    v(FACULTY-GAP)
    text(size: SIZE-XLARGE, [-- #faculty --])
  }

  // ---------- Title ---------------------------------------

  v(2fr)

  text(weight: "bold", fill: luma(0), size: SIZE-XLARGE, title)
  if subtitle != none {
    v(SUBTITLE-GAP)
    text(fill: luma(80), size: SIZE-LARGE, subtitle)
  }

  // ---------- Confidentiality Marker (optional) ---------------------------------------

  if (confidentiality-marker.display) {
    let size = 7em
    let x-offset = 0pt
    let y-offset = if (many-authors) { 7pt } else { 0pt }

    if ("offset-x" in confidentiality-marker) {
      x-offset = confidentiality-marker.offset-x
    }
    if ("offset-y" in confidentiality-marker) {
      y-offset = confidentiality-marker.offset-y
    }
    if ("size" in confidentiality-marker) {
      size = confidentiality-marker.size
    }

    let color = if (show-confidentiality-statement) { red } else { green.darken(5%) }

    place(
      right,
      dx: 35pt + x-offset,
      dy: -70pt + y-offset,
      circle(radius: size / 2, fill: color),
    )
  }

  // ---------- Type of Thesis / Degree ---------------------------------------

  v(2fr)

  if (type-of-thesis != none and type-of-thesis.len() > 0) {
    // A line break in `type-of-thesis` separates the "for the degree of" phrase from the degree itself, which the LaTeX template sets apart by a `\vspace` rather than by leading alone.
    set text(size: SIZE-LARGE)
    stack(
      dir: ttb,
      spacing: DEGREE-GAP,
      ..if type(type-of-thesis) == str { type-of-thesis.split("\n") } else { (type-of-thesis,) },
    )
  }

  // ---------- Author(s) ---------------------------------------

  v(1fr)

  text(size: SIZE-LARGE, TITLEPAGE_SUBMITTED_BY.at(language))
  v(AUTHOR-GAP)
  stack(
    dir: ttb,
    spacing: AUTHOR-GAP,
    ..authors.map(author => text(weight: "bold", size: SIZE-LARGE, author.name)),
  )
  v(AUTHOR-GAP)
  text(
    TITLEPAGE_STUDENT_ID.at(language)
      + " "
      + authors.map(author => str(author.student-id)).join(", "),
  )

  // ---------- Info-Block ---------------------------------------
  //
  // `label : value` rows in a three-column grid, with the colons aligned in a column of their own the way the LaTeX template's `tabular{lll}` sets them. Only the referees appear here; the submission date belongs to the copyright notice and the declaration of authorship, which both carry it already.

  v(2fr)

  let info-row(label, value) = (text(label), text(":"), text(value))

  grid(
    columns: (auto, auto, auto),
    row-gutter: 0.9em,
    column-gutter: 0.75em,
    align: (right, center, left),

    // company
    ..if (not at-university) {
      info-row(
        TITLEPAGE_COMPANY.at(language),
        authors
          .map(author => {
            let company-address = ""

            // company name
            if ("name" in author.company and author.company.name != none and author.company.name != "") {
              company-address += author.company.name
            } else {
              panic("Author '" + author.name + "' is missing a company name. Add the 'name' attribute to the company object.")
            }

            // company address (optional)
            if ("post-code" in author.company and author.company.post-code != none and author.company.post-code != "") {
              company-address += ", " + author.company.post-code
            }

            // company city
            if ("city" in author.company and author.company.city != none and author.company.city != "") {
              company-address += ", " + author.company.city
            } else {
              panic("Author '" + author.name + "' is missing the city of the company. Add the 'city' attribute to the company object.")
            }

            // company country (optional)
            if ("country" in author.company and author.company.country != none and author.company.country != "") {
              company-address += ", " + author.company.country
            }

            company-address
          })
          .dedup()
          .join(" | "),
      )
    } else { () },

    // university supervisor
    ..if ("ref" in supervisor and type(supervisor.ref) == str) {
      info-row(TITLEPAGE_SUPERVISOR_REF.at(language), supervisor.ref)
    } else { () },
    ..if ("co-ref" in supervisor and type(supervisor.co-ref) == str) {
      info-row(TITLEPAGE_SUPERVISOR_COREF.at(language), supervisor.co-ref)
    } else { () },
  )
}
