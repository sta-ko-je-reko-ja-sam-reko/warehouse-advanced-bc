# Reports

What this app prints, and the decision that made printing possible without guessing.

## Three reports

| Report | Reads | Reached from |
|---|---|---|
| **Handling unit contents** | A handling unit and its lines | *Print contents* on the handling unit card |
| **Warehouse task list** | The warehouse task queue | *Print list* on the warehouse tasks page |
| **Count sheet** | A count sheet and its lines | *Print sheet* on the count sheet card |

Each is a plain list over the app's own tables, with the filters a person would actually want on the
request page. None of them reads anything outside this app.

## No layout file, and why that is the point

**These reports ship with no RDLC and no Word layout.** Business Central generates a built-in layout at
run time for a report that has none, and a customer adds their own through *Report Layouts* — which is
how a Business Central product is meant to be extended anyway.

That is a deliberate choice, not a shortcut. A layout is XML or a binary document that **no compiler
checks and no test can read**: it is the one thing in this repository that could be wrong in a way
nothing here would catch. Shipping the dataset and letting the platform draw it means every part of
these reports — the tables, the columns, the filters, the captions — is compiler-verified, and the part
that is not verifiable is not shipped at all.

The consequence, stated plainly: **the default output is functional rather than designed.** It is a
readable list, not a laid-out picking document with a logo and a barcode. A warehouse that wants one
adds a layout; nothing in the app has to change for that to work.

## The one piece of logic, and where it is not

A blind count works by the counter not knowing what the system expects. Printing that number on the
sheet they carry defeats the entire feature, silently — and a report layout is the easiest place in the
app for that to happen, because nothing about a layout tells you what it leaks.

So the decision is not in the report. `WHA Count Sheet Logic.ExpectedQuantityToPrint` answers it, the
report asks, and two tests assert both halves. That is the rule for anything else these reports ever
need to decide: **the report asks; it does not decide.**

## Not done

- **No labels.** The SSCC this app generates still does not print as a barcode. That needs a layout with
  a barcode font or image, which is exactly the unverifiable part above, and it needs to be looked at on
  paper before anybody can say it works.
- **No packing list, delivery note or CMR.** The handling unit contents report is the nearest thing, and
  it is a contents list rather than a document anybody would send to a customer.
- **No printer routing.** Where a report comes out is Business Central's own printer selection; nothing
  here routes by zone or station.
- **Nothing has been printed.** Like everything else in this app, these have never run.
