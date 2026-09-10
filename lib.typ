#import "@preview/codelst:2.0.2": *
#import "@preview/hydra:0.6.1": hydra
#import "@preview/abbr:0.3.0"
#import "@preview/glossarium:0.5.6": gls, glspl, make-glossary, print-glossary, register-glossary
#import "locale.typ": APPENDIX, LIST_OF_ABBREVIATIONS, REFERENCES, TABLE_OF_CONTENTS
#import "titlepage.typ": *
#import "info-page.typ": *
#import "confidentiality-statement.typ": *
#import "declaration-of-authorship.typ": *
#import "check-attributes.typ": *

// Workaround for the lack of an `std` scope.
#let std-bibliography = bibliography

#let hda-abbr = abbr

#let clean-hda(
  title: none,
  subtitle: none,
  authors: (:),
  language: none,
  edition: "print",
  at-university: none,
  confidentiality-marker: (display: false),
  type-of-thesis: none,
  show-confidentiality-statement-at-beginning: true,
  show-confidentiality-statement-at-end: false,
  show-declaration-of-authorship-at-beginning: true,
  show-declaration-of-authorship-at-end: false,
  show-table-of-contents: true,
  show-table-of-figures: true,
  show-table-of-tables: true,
  show-info-page: false,
  show-abstract: true,
  abstract: none,
  appendix: none,
  confidentiality-statement-content: none,
  declaration-of-authorship-content: none,
  titlepage-content: none,
  university: none,
  university-location: none,
  university-short: none,
  city: none,
  supervisor: (:),
  date: none,
  date-format: "[day].[month].[year]",
  bibliography: none,
  glossary: none,
  bib-style: "ieee",
  math-numbering: "(1)",
  enable-math-numbering: false,
  logo-left: image("logo_fbi_eut.pdf"),
  logo-right: none,
  ignored-link-label-keys-for-highlighting: (),
  abbr-list-csv: "abbr.csv",
  abbr-page-break: true,
  abbr-outlined: false,
  table-of-figures-page-break: true,
  table-of-figures-outlined: false,
  table-of-tables-page-break: true,
  table-of-tables-outlined: false,
  figure-short-captions: (:),
  pdf-version: "v1.0.0",
  body,
) = {
  // check required attributes
  let show-confidentiality-statement = show-confidentiality-statement-at-beginning
  let show-declaration-of-authorship = show-declaration-of-authorship-at-beginning
  let many-authors = authors.len() > 3
  check-attributes(
    title,
    authors,
    language,
    edition,
    at-university,
    confidentiality-marker,
    type-of-thesis,
    show-confidentiality-statement,
    show-declaration-of-authorship,
    show-table-of-contents,
    show-abstract,
    abstract,
    appendix,
    university,
    university-location,
    supervisor,
    date,
    city,
    bibliography,
    glossary,
    bib-style,
    logo-left,
    logo-right,
    university-short,
    math-numbering,
    ignored-link-label-keys-for-highlighting,
  )

  // ---------- Fonts & Related Measures ---------------------------------------

  let body-font = "TeX Gyre Pagella"
  let body-size = 11pt
  let mono-font = "DejaVu Sans Mono"
  let heading-font = "TeX Gyre Pagella"
  let chapter-number-font = ("Euler Math", "New Computer Modern Math") // AMS Euler, à la classicthesis's `eulerchapternumbers`; falls back to New Computer Modern Math (bundled with Typst) wherever Euler isn't installed.
  let h1-size = body-size
  let h2-size = body-size
  let h3-size = body-size
  let h4-size = body-size
  let page-grid = 13.6pt * 1.05 // KOMA's 11pt baselineskip with classicthesis's `\linespread{1.05}` for Palatino/Pagella
  let chapter-number-size = 70pt // matches classicthesis's fixed `\DeclareFixedFont` chapter-numeral size
  // classicthesis-config.tex:146 `\captionsetup{font=small}`: KOMA's `\small` step at an 11pt base
  // document class is a fixed 10pt (KOMA's font-size steps are table-driven, not a linear fraction
  // of the body size).
  let caption-size = 10pt
  // classicthesis's `\spacedlowsmallcaps` = `\textls[80]{\scshape\MakeTextLowercase{#1}}`
  // (classicthesis.sty:349): small caps plus 80/1000 em extra letter-spacing, always applied
  // together. One constant + helper so every lowsmallcaps call site stays in sync. Distinct from
  // the separate 1.5pt tracking used for the ALL-CAPS chapter-title treatment below (classicthesis's
  // `\spacedallcaps`, `\textls[160]{...}`) — that one is untouched.
  let lowsmallcaps-tracking = 0.08em
  let spaced-lowsmallcaps(body) = text(tracking: lowsmallcaps-tracking, smallcaps(all: true, body))

  // Latex Values based from @AI analysis
  let classic-text-width = 370pt
  let classic-layout-height = 750pt
  let base-side-margin = (210mm - classic-text-width) / 2
  let page-margin = (
    top: 2.5cm,
    bottom: 3cm,
    left: base-side-margin + 2.5mm, // BCOR = 5mm => shift by half to the inner side
    right: base-side-margin - 2.5mm,
  )

  // ---------- Basic Document Settings ---------------------------------------

  set document(title: title, author: authors.map(author => author.name))
  let in-frontmatter = state("in-frontmatter", true) // to control page number format in frontmatter
  let in-body = state("in-body", true) // to control heading formatting in/outside of body

  // customize look of figure
  set figure.caption(separator: [ --- ], position: bottom)
  show figure.caption: set text(size: caption-size)
  // KOMA's `floatperchapter=true` (classicthesis-config.tex:34): figures/tables number as
  // "Chapter.N". Combines the chapter's own heading-counter value with the figure's per-kind
  // counter; the actual per-chapter reset happens in the level-1 heading show rule below.
  set figure(numbering: (..num) => numbering(
    "1.1",
    counter(heading).get().first(),
    num.pos().first(),
  ))

  // math numbering
  if (enable-math-numbering) {
    set math.equation(numbering: math-numbering)
  }

  // show all headings in the exported PDF's outline
  set heading(bookmarked: true)

  // initialize `glossarium`
  // CAVEAT: all `figure` show rules must come before this (see `glossarium` docs)
  show: make-glossary

  // register the glossary passed in `glossary`
  if (glossary != none) {
    register-glossary(glossary)
  }

  // Colorlinks (classicthesis-config.tex:196-204's `\hypersetup{colorlinks=true,
  // urlcolor=webbrown, linkcolor=RoyalBlue, citecolor=webgreen, ...}`) — only in the digital
  // edition; the print edition keeps every link/citation/URL in plain black. The `show` rules
  // themselves must stay unconditional (a `show` nested inside `if edition == "digital" { … }`
  // would only apply to the remainder of that `if`-block, which is empty, and thus never reach
  // the rest of the document) — instead the colors themselves collapse to black in print.
  let internal-link-color = if edition == "digital" { rgb("#1068c0") } else { luma(0) } // dvipsnames' RoyalBlue, sampled from latex/thesis.pdf
  let citation-color = if edition == "digital" { rgb(0%, 50%, 0%) } else { luma(0) } // classicthesis.sty:150's webgreen, rgb{0,.5,0}
  let url-color = if edition == "digital" { rgb(60%, 0%, 0%) } else { luma(0) } // classicthesis.sty:150's webbrown, rgb{.6,0,0}
  show ref: set text(fill: internal-link-color)
  show cite: set text(fill: citation-color)
  show link: it => text(fill: if type(it.dest) == str { url-color } else { internal-link-color }, it)

  // ========== TITLEPAGE ========================================

  if (titlepage-content != none) {
    titlepage-content
  } else {
    titlepage(
      authors,
      date,
      heading-font,
      language,
      logo-left,
      logo-right,
      many-authors,
      supervisor,
      title,
      subtitle,
      type-of-thesis,
      university,
      university-location,
      at-university,
      date-format,
      show-confidentiality-statement,
      confidentiality-marker,
      university-short,
      page-grid,
      page-margin,
    )
  }
  counter(page).update(1)

  // ---------- Heading Format (Part I) ---------------------------------------
  // Frontmatter section titles (ToC, list of figures/tables/abbreviations, abstract) get the
  // same all-caps/tracked/ruled treatment as body chapters, just without a chapter numeral —
  // they carry no `counter(heading)` and manage their own page breaks via their own call sites.
  show heading: set text(font: heading-font)
  show heading.where(level: 1): it => {
    v(page-grid * 1.5)
    text(
      tracking: 1.5pt,
      weight: "regular",
      size: h1-size,
      top-edge: 0em,
      bottom-edge: 0em,
      upper(it.body),
    )
    line(length: 100%, stroke: 0.5pt)
    v(0.35 * page-grid)
  }

  // ---------- Page Setup ---------------------------------------

  // adapt body text layout to basic measures
  set text(
    font: body-font,
    lang: language,
    size: body-size,
    top-edge: 0.75 * body-size,
    bottom-edge: -0.25 * body-size,
    fill: luma(0),
  )
  set par(
    spacing: page-grid - body-size,
    leading: page-grid - body-size,
    first-line-indent: 1em, // TODO
    justify: true,
  )

  set page(
    paper: "a4",
    margin: page-margin,
    header: context {
      // pages opening with a level-1 heading (chapters, but also the ToC/list-of-*
      // and bibliography/glossary titles, which are level-1 headings too) get no
      // running header and thus no page number, matching the hda-latex template's
      // `plain` chapter-opening page style.
      let starts-with-h1 = query(heading.where(level: 1)).any(h => h.location().page() == here().page())
      if not starts-with-h1 {
        block(width: 100%)[
          // old-style figures blend with the small-caps title/roman-esque page number here,
          // matching classicthesis's running-header look; the body text and the large margin
          // chapter numeral deliberately keep lining figures (`set text` default) instead.
          #set text(number-type: "old-style")
          #spaced-lowsmallcaps(text(font: heading-font, size: body-size, context {
            hydra(
              // `hydra`'s `selectors.by-level(max: 2)` isn't re-exported by the package's
              // entrypoint, so its `max`-level selector shape is replicated here directly
              // to cap the running header at level 2 (chapter or section, never deeper).
              // `display: auto` (hydra's default) prepends the heading's own numbering.
              (primary: (target: heading, filter: (ctx, e) => e.level <= 2), ancestors: none),
              use-last: true,
              skip-starting: false,
            )
          }))
          #place(
            top + left,
            dx: 100% + 1.5em, // hangs in the margin, outside the text column, like the chapter numeral below
            text(font: heading-font, size: body-size, context {
              if in-frontmatter.get() {
                counter(page).display("i") // roman page numbers for the frontmatter
              } else {
                counter(page).display("1") // arabic page numbers for the rest of the document
              }
            }),
          )
          #v(0.5em)
          #line(length: 100%, stroke: 0.5pt)
        ]
      }
    },
    header-ascent: page-grid,
  )

  // ========== FRONTMATTER ========================================

  // ---------- INFO PAGE with Confidentiality Statement------------

  if (show-info-page) {
    pagebreak()
    info-page(
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
    )
  }

  // ---------- Abstract ---------------------------------------

  if (show-abstract and abstract != none) {
    heading(level: 1, numbering: none, outlined: false, ABSTRACT.at(language))
    text(abstract)
    pagebreak()
  }

  // ---------- ToC (Outline) ---------------------------------------
  set page(numbering: "i", footer: none) // numbering for List fo Abbreviations and other entries before body

  // top-level TOC entries in small caps, with the same dot leader as the other levels
  show outline.entry.where(level: 1): it => {
    set block(above: 0pt, below: 0pt)
    set text(font: heading-font, size: body-size, number-type: "old-style")
    link(
      it.element.location(), // make entry linkable
      // dot leader (not just a bare `1fr` box) and explicit box height matter here: on a
      // line whose filler renders no visible glyphs — no leader, or a wrapped entry whose
      // page number lands alone on the last line — Typst computes a shorter line box than
      // for ordinary text, which silently eats into the gap before the following entry.
      it.indented(
        it.prefix(),
        spaced-lowsmallcaps(it.body())
          + box(width: 1fr, height: 1em, repeat([.], gap: 2pt), baseline: 30%)
          + it.page(),
      ),
    )
  }

  // other TOC entries in regular with adapted filling
  show outline.entry.where(level: 2).or(outline.entry.where(level: 3)): it => {
    set block(above: 0pt, below: 0pt)
    set text(font: heading-font, size: body-size, number-type: "old-style")
    link(
      it.element.location(), // make entry linkable
      it.indented(
        it.prefix(),
        it.body() + "  " + box(width: 1fr, height: 1em, repeat([.], gap: 2pt), baseline: 30%) + "  " + it.page(),
      ),
    )
  }
  if (show-table-of-contents) {
    outline(
      title: TABLE_OF_CONTENTS.at(language),
      indent: auto,
      depth: 3,
    )
  }

  // Abbreviations

  if abbr-page-break {
    pagebreak()
  }
  show: abbr.show-rule
  abbr.load(abbr-list-csv)
  abbr.config(style: key => {
    // same scoping constraint as the colorlinks block above: `set` must stay unconditional so it
    // reaches the trailing `key`, so the color itself (not the `set` call) is what collapses to
    // black in the print edition.
    let val = if text.weight <= "medium" { 15% } else { 30% }
    let abbr-color = if edition == "digital" { blue.darken(val) } else { luma(0) }
    set text(fill: abbr-color)
    key
  })
  set heading(outlined: abbr-outlined)
  abbr.list(title: LIST_OF_ABBREVIATIONS.at(language), columns: 1)
  set heading(outlined: true)

  // Figures
  show outline.entry.where(level: 1): it => {
    set block(above: 0pt, below: 0pt)
    set text(font: heading-font, size: body-size, number-type: "old-style")
    // figures and tables (both wrapped in Typst's `figure()`) may provide a
    // `figure-short-captions` entry (keyed by their label) so the list of figures/tables
    // stays free of the citations/code identifiers their full in-text caption carries;
    // other outline entries (chapters) fall back to the full body.
    let entry-body = if it.element.func() == figure {
      let key = if it.element.has("label") { str(it.element.label) } else { none }
      let short = if key != none { figure-short-captions.at(key, default: none) } else { none }
      if short != none { short } else { it.body() }
    } else {
      it.body()
    }
    link(
      it.element.location(), // make entry linkable
      it.indented(
        it.prefix(),
        entry-body + "  " + box(width: 1fr, height: 1em, repeat([.], gap: 2pt), baseline: 30%) + "  " + it.page(),
      ),
    )
  }

  if (show-table-of-figures) {
    if table-of-figures-page-break {
      pagebreak()
    }
    heading(outlined: table-of-figures-outlined)[#TABLE_OF_FIGURES.at(language)]
    outline(
      title: none,
      target: figure.where(kind: image),
      indent: auto,
      depth: 3,
    )
  }

  if (show-table-of-tables) {
    if table-of-tables-page-break {
      pagebreak()
    }
    heading(outlined: table-of-tables-outlined)[#TABLE_OF_TABLES.at(language)]
    outline(
      title: none,
      target: figure.where(kind: table), //TODO verfiy
      indent: auto,
      depth: 3,
    )
  }

  set page(numbering: "1") // numbering for body body
  in-frontmatter.update(false) // end of frontmatter
  counter(page).update(1) // so the first chapter starts at page 1 (now in arabic numbers)

  // ========== DOCUMENT BODY ========================================

  // ---------- Heading Format (Part II: H1-H4) ---------------------------------------

  set heading(numbering: "1.1.1")

  show heading: it => {
    set par(leading: 4pt, justify: false)
    text(it, top-edge: 0.75em, bottom-edge: -0.25em)
    v(page-grid, weak: true)
  }

  show heading.where(level: 1): it => {
    set par(leading: 0pt, justify: false)
    pagebreak()
    // floatperchapter resets figure/table numbering at every chapter (including the appendix),
    // analogous to classicthesis.sty:668-684's separate \c@figure/\c@table resets.
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: raw)).update(0) // Masterarbeit.typ's `kind: raw` figures; otherwise a no-op reset
    context {
      if in-body.get() {
        block(width: 100%)[
          #v(page-grid * 1.5)
          #place(
            top + left,
            dx: 100% + 1.5em, // hangs in the margin, outside the text column, clear of the title
            text(
              counter(heading).display(),
              top-edge: "bounds",
              size: chapter-number-size,
              weight: 0,
              // classicthesis.sty:148 `halfgray = gray{0.55}`; empirically verified against
              // latex/thesis.pdf (median sampled gray 140/255 ≈ 54.9%) vs. this value's own
              // previous 111/255 ≈ 43.5%, which rendered measurably darker than the original.
              fill: luma(55%),
              font: chapter-number-font,
            ),
          )
          #text(
            // all-caps, letter-spaced, and close to body size, à la classicthesis
            tracking: 1.5pt,
            weight: "regular",
            size: h1-size,
            top-edge: 0em,
            bottom-edge: 0em,
            upper(it.body),
          )
          #v(0.4 * page-grid)
          #line(length: 100%, stroke: 0.5pt)
          #v(0.35 * page-grid)
        ]
      } else {
        v(2 * page-grid)
        text(size: 2 * page-grid, counter(heading).display() + h(0.5em) + it.body) // appendix
      }
    }
  }

  // LaTeX original (classicthesis.sty:424-432): \section uses \spacedlowsmallcaps for the
  // whole heading (number + title); \subsection/\subsubsection use plain italic
  // (\normalsize\itshape). This template's `set heading(numbering: "1.1.1")` above is a
  // 3-level scheme, so Typst's level 4 here IS LaTeX's \subsubsection, not \paragraph — there
  // is no slot for \paragraph's own \spacedlowsmallcaps run-in style, so the previous
  // smallcaps+semibold level-4 treatment is dropped rather than repurposed.
  show heading.where(level: 2): it => {
    v(16pt) + spaced-lowsmallcaps(text(size: h2-size, number-type: "old-style", it))
  }
  show heading.where(level: 3): it => {
    v(16pt) + text(size: h3-size, number-type: "old-style", style: "italic", it)
  }
  show heading.where(level: 4): it => { v(16pt) + text(size: h4-size, style: "italic", it) }

  // ---------- Body Text ---------------------------------------

  body

  // ========== APPENDIX ========================================

  in-body.update(false)
  set heading(numbering: "A.1")
  counter(heading).update(0)

  // ---------- Appendix (other contents) ---------------------------------------

  if (appendix != none) {
    // the user has to provide heading(s)
    appendix
  }

  // ---------- Bibliography ---------------------------------------

  show std-bibliography: set heading(numbering: "A.1")
  if bibliography != none {
    set std-bibliography(
      title: REFERENCES.at(language),
      style: bib-style,
    )
    bibliography
  }

  // ---------- Glossary  ---------------------------------------

  if (glossary != none) {
    heading(level: 1, GLOSSARY.at(language))
    print-glossary(glossary)
  }

  // ========== LEGAL BACKMATTER ========================================

  // ---------- Confidentiality Statement ---------------------------------------

  if (show-confidentiality-statement-at-end) {
    set heading(numbering: it => h(-18pt) + "", outlined: false)
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

  // ---------- Declaration Of Authorship ---------------------------------------

  if (show-declaration-of-authorship-at-end) {
    set heading(numbering: it => h(-18pt) + "", outlined: false)
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
    )
  }
}
