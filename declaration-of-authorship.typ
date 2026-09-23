#import "locale.typ": *

#let declaration-of-authorship(
  authors,
  title,
  declaration-of-authorship-content,
  date,
  language,
  many-authors,
  at-university,
  city,
  date-format,
  edition,
) = {
  set par(first-line-indent: 0em)

  heading(level: 1, numbering: none, outlined: false, DECLARATION_OF_AUTHORSHIP_TITLE.at(language))
  v(1em)

  if (declaration-of-authorship-content != none) {
    declaration-of-authorship-content
  } else {
    if (authors.len() == 1) {
      par(justify: true, DECLARATION_OF_AUTHORSHIP_SECTION.at(language))
    } else {
      par(justify: true, DECLARATION_OF_AUTHORSHIP_SECTION.at(language))
    }
  }

  let end-date = if (type(date) == datetime) {
    date
  } else {
    date.at(1)
  }

  let location-date = if (at-university) {
    city + [, ] + end-date.display(date-format)
  } else {
    let authors-by-city = authors.map(author => author.company.city).dedup()

    authors-by-city.join(", ", last: AND.at(language)) + [ ] + end-date.display(date-format)
  }

  v(2em)
  // The print edition is hand-signed and hand-dated after printing, so place/date stay
  // blank there rather than pre-filled — `hide` keeps the line's layout space reserved.
  if (edition == "print") {
    hide(text(style: "italic", location-date))
  } else {
    text(style: "italic", location-date)
  }

  v(1em)
  if (many-authors) {
    grid(
      columns: (1fr, 1fr),
      gutter: 20pt,
      ..authors.map(author => align(center, block(width: 80%)[
        #rect(
          width: 100%,
          height: 3.5em,
          inset: 1pt,
          stroke: (top: none, y: none, bottom: black),
          if edition != "print" and author.keys().contains("signature") {
            box(author.signature)
          },
        )
        #align(center, author.name)
      ]))
    )
  } else {
    for author in authors {
      align(right, block(width: 40%)[
        #rect(
          width: 100%,
          height: 4em,
          inset: 1pt,
          stroke: (top: none, y: none, bottom: black),
          if edition != "print" and author.keys().contains("signature") {
            box(author.signature)
          },
        )
        #align(center, author.name)
      ])
    }
  }
}
