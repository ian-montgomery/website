#set page(paper: "a4", margin: (x: 1.5cm, top: 1.5cm, bottom: 1.5cm))
#set text(font: "Liberation Sans", size: 9pt, fill: rgb("#1e293b"))

// Single source of truth: data/*.yaml (shared with the website and Markdown CV)
#let basics = yaml("/data/basics.yaml")
#let private = json("/local/private.json")
#let jobs = yaml("/data/jobs.yaml")
#let education = yaml("/data/education.yaml")
#let skills = yaml("/data/skills.yaml")

#let months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
#let fmt-date(iso) = {
  let parts = iso.split("-")
  months.at(int(parts.at(1)) - 1) + " " + parts.at(0)
}
#let date-range(start, end) = {
  if end == none {
    fmt-date(start) + " – Present"
  } else {
    fmt-date(start) + " – " + fmt-date(end)
  }
}

// Header
#align(center)[
  #text(size: 20pt, weight: "black", fill: rgb("#0f172a"))[#basics.name] \
  #v(2pt)
  #text(size: 11pt, weight: "bold", fill: rgb("#0284c7"))[#basics.label] \
  #v(4pt)
  #text(size: 8.5pt, fill: rgb("#475569"))[
    #basics.email#if private.phone != "" [#h(6pt) • #h(6pt) #private.phone] #h(6pt) • #h(6pt) #basics.city, #basics.country
  ] \
  #v(2pt)
  #text(size: 8.5pt, fill: rgb("#0284c7"))[
    #basics.socials.map(s => s.url.replace("https://", "")).join(" • ")
  ]
]

#v(6pt)
#line(length: 100%, stroke: 0.5pt + rgb("#cbd5e1"))

// Summary
#v(6pt)
#text(size: 8.5pt, fill: rgb("#334155"))[#basics.summary]

// Skills
#v(10pt)
#text(weight: "black", size: 12pt, fill: rgb("#0f172a"))[Skills]
#v(4pt)

#for cat in skills.categories [
  #block[
    #text(weight: "bold", size: 9pt)[#cat.name:] #h(4pt)
    #text(size: 8.5pt)[#cat.skills.map(s => skills.skills.at(s, default: (name: s)).name).join(" · ")]
  ]
  #v(1pt)
]

// Work Experience
#v(10pt)
#text(weight: "black", size: 12pt, fill: rgb("#0f172a"))[Work Experience]
#v(4pt)

#for job in jobs [
  #block[
    #text(weight: "bold", size: 10pt)[#job.title] #h(1fr) #text(style: "italic", size: 8.5pt)[#date-range(job.start, job.end)] \
    #text(weight: "bold", fill: rgb("#0284c7"))[#job.at("organization_pdf", default: job.organization)] #h(6pt) • #h(6pt) #text(size: 8.5pt, fill: rgb("#64748b"))[#job.employment_type · #job.work_model · #job.location]
    #v(2pt)
    #for bullet in job.bullets_pdf [
      - #bullet
    ]
  ]
  #v(6pt)
]

// Education
#v(10pt)
#text(weight: "black", size: 12pt, fill: rgb("#0f172a"))[Education]
#v(4pt)

#for edu in education [
  #block[
    #text(weight: "bold", size: 10pt)[#edu.title] #h(1fr) #text(style: "italic", size: 8.5pt)[#date-range(edu.start, edu.end)] \
    #text(weight: "bold", fill: rgb("#0284c7"))[#edu.institution] #h(6pt) • #h(6pt) #text(size: 8.5pt, fill: rgb("#64748b"))[#edu.mode#if edu.at("qualification", default: none) != none [ · #edu.qualification]#if edu.at("minor", default: none) != none [ · Minor: #edu.minor]]
    #v(2pt)
    #edu.description
  ]
  #v(6pt)
]

// Footer Legal Consent Statement
#v(12pt)
#align(center)[
  #text(size: 7.5pt, fill: rgb("#94a3b8"), style: "italic")[
    I hereby give consent for my personal data included in my application to be processed for the purposes of the recruitment process.
  ]
]
