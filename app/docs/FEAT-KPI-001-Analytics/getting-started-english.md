# FEAT-KPI-001 - Analytics

Five numbers about how your warehouse is running, worked out from the work your own people have
already done. Nothing here is typed in, and nothing here is estimated.

> **It needs history.** Every figure is measured from finished warehouse jobs and finished vehicle
> visits. On a warehouse that has just started using the app, every figure is zero — and that is the
> right answer, not a fault.

## Turn analytics on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. Choose the **Analytics** row, then **Next**.
4. Switch on **Enable this feature**, then **Next** and **Finish**.
5. Close the feature list. Your session restarts so the change takes effect.

The figures come from other features, so how much you get depends on what else you use:

- **Directed work** gives you jobs finished, the put-away lead time, and short picks.
- **Dock and yard** gives you the two vehicle figures.

A feature you do not use simply reads zero. Nothing breaks.

## Say what a figure covers

1. Choose the search icon, enter **Analytics setup**, and choose the related link.
2. **Measure the last** — how many days a figure covers when nobody says otherwise. A week reacts
   quickly and jumps about; a month is steady and hides the week things went wrong.
3. **Capture for location** — which site a kept set of figures is about. Leave it blank to measure
   the whole company as one, which is right until two sites start behaving differently.

## Look at the figures

Choose the search icon, enter **Warehouse KPIs**, and choose the related link.

Change **Location**, **From date** or **To date** at the top and everything is worked out again
straight away. Looking at figures never changes anything, so this screen is safe to leave open or to
hand to anybody.

You get five lines, each with the number, the unit it is in, and **What it counts** — a sentence
saying what goes into it and what it deliberately leaves out. Read that sentence before quoting the
number to anybody:

- **Jobs finished** — how many warehouse jobs were completed. It counts jobs, not units, so a carton
  weighs the same as a pallet.
- **Hours from raised to put away** — how long put-away work waits. The clock starts when the job was
  raised, **not** when the lorry arrived.
- **Picks that came up short** — the share of picks that came back with less than they asked for.
  Every one of those is an order somebody has to deal with.
- **Minutes a vehicle is on site** — gate to gate. This is what a haulier bills you on.
- **Minutes waiting for a door** — gate to door. This is the part you control.

A figure showing zero usually means there was nothing to measure. Check the period before reading
anything into it.

## Keep a period so you can compare it

Choose **Keep these figures** on the same screen, or **Capture the figures now** on the analytics
setup.

Then choose the search icon, enter **KPI snapshots**, and choose the related link. Every figure you
have ever kept is here, with the days it covered and who took it.

A figure is coloured against the last one taken for the same measure and site: **green** when it
moved the right way, **red** when it moved the wrong way. That is all the app will say. It has no
idea what a good number is for your warehouse, and it will not pretend to.

**Only compare periods of the same length.** A month against a week tells you nothing.

Capturing the same period twice replaces the figures rather than keeping two answers.

## Have it captured for you

Ask an administrator to create a **job queue entry** for codeunit **WHA KPI Scheduler**. Each run
keeps a snapshot of every measure for the period in your analytics setup, so the history builds itself
and a trend is something you can read rather than something you had to remember to record.

A **Location code** filter on the entry captures one site; leave it empty for the whole company.

## What analytics does not do yet

- **There is no dock-to-stock figure.** Nothing connects a put-away to the lorry that brought the
  goods, so the app cannot honestly time one from the other. What you get instead are the two halves
  of it: how long a vehicle is on site, and how long put-away work waits.
- **There are no targets.** Nothing is ever red for being a bad number, only for moving the wrong
  way.
- **A missed capture is a gap for ever.** A scheduled capture keeps figures for the period ending
  today. If the schedule breaks for a week, that week is simply missing and nothing fills it in
  afterwards.
- **Nothing about people.** How long the work takes against how long it should is in labour
  management, not here.
- **No charts and no home-page tiles.** Snapshots are a list; to draw a trend, export it.

## Load sample data

There is no sample data of its own to load. Switching **Load sample data** on captures one set of
figures from whatever your company has already done — so load the other features' sample data first
if you want something other than zeroes to look at.
