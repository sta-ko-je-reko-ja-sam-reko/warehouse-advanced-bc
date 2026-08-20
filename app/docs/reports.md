# Reports

What this app prints, where the layouts live, and how far they have actually been verified.

## Three reports

| Report | Reads | Reached from |
|---|---|---|
| **Handling unit contents** | A handling unit and its lines | *Print contents* on the handling unit card |
| **Warehouse task list** | The warehouse task queue | *Print list* on the warehouse tasks page |
| **Count sheet** | A count sheet and its lines | *Print sheet* on the count sheet card |

Each is a plain list over the app's own tables, with the filters a person would actually want on the
request page. None reads anything outside this app.

## Where the layouts live

Layouts are **not** in `app/src/`. They sit in `app/layout/<Feature>/<Name>.rdlc`, mirroring the feature
folders, and the report points at one with a path from the project root:

```al
RDLCLayout = './layout/HandlingUnit/HandlingUnitContents.rdlc';
```

That keeps `app/src/` to AL and nothing else, and it is the shape the base application itself uses — its
own package carries `src/` and `layout/` as separate trees.

**All three are RDLC, including the two that are really documents.** A Business Central Word layout is a
`.docx` carrying a custom XML part and content controls bound to it, and Business Central generates that
part itself; hand-authoring one is not something that can be done reliably or checked afterwards. RDLC is
XML, so it can at least be read, diffed and checked. A warehouse that wants a Word layout adds one
through *Report Layouts* without any change here.

## What the compiler does and does not check

Worth knowing before trusting a green build. Verified against `alc 17.0.34.45391`:

| | |
|---|---|
| A layout containing only `<Report><Unclosed>` | **Compiles clean** |
| `RDLCLayout` pointing at a file that does not exist | **Compiles clean** |
| Whether the layout is embedded in the built `.app` | Not reported, but it **is** — confirmed by opening the package |
| The dataset in the layout | **Rewritten by the compiler.** `alc` syncs the report's columns into the `.rdlc` on build and adds a `<Column>Format` companion for each formatted column |

So a build proves the layout was picked up, and proves nothing about whether it is right.

## The check the compiler does not do

`tools/rdlc-check/check-rdlc.py`, run from the repository root. For every report with a layout it
checks that:

- the layout is well-formed XML and really is a `Report`
- it declares a dataset named `DataSet_Result`, which is what Business Central binds
- every `<Field>` it declares is a column on the AL report, or a compiler-generated `…Format` companion
- every `Fields!X.Value` refers to a declared field
- every `Parameters!X.Value` is a caption the report publishes (`IncludeCaption = true`) or a label it
  declares — a wrong parameter name renders blank rather than failing
- textbox names are unique, which RDLC requires and nothing else enforces

It found a real discrepancy on its first run, which is how the compiler's dataset rewriting was
discovered rather than assumed.

**What it cannot tell you is whether any of it renders**, or whether the result looks like something a
warehouse would want to hold. That needs the container and a pair of eyes, and neither has happened.

## The one piece of logic, and where it is not

A blind count works by the counter not knowing what the system expects. Printing that number on the sheet
they carry defeats the entire feature, silently — and a layout is the easiest place in the app for that
to happen, because nothing about a layout tells you what it leaks.

So the decision is not in the report. `WHA Count Sheet Logic.ExpectedQuantityToPrint` answers it, the
report asks, and two tests assert both halves. The rule for anything else these reports ever need to
decide: **the report asks; it does not decide.**

## Not done

- **Nothing has been rendered.** The layouts are checked as far as static analysis reaches and no
  further.
- **They are functional, not designed.** A readable list with a title and column headers — not a
  laid-out picking document with a logo, and no barcode anywhere.
- **No labels.** The SSCC this app generates still does not print as a barcode. That needs a barcode font
  or image in a layout, and it needs looking at on paper before anybody can say it works.
- **No packing list, delivery note or CMR.** Handling unit contents is the nearest thing, and it is a
  contents list rather than a document anybody would send to a customer.
- **No printer routing.** Where a report comes out is Business Central's own printer selection.
