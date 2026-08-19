# FEAT-SLOT-001 - Slotting

Bin ranking already says which of your bins are the good ones — near the dispatch area, at waist
height, first on the round. Nothing has ever said which *items* deserve them, so items tend to keep
whichever bin they were first put in.

Slotting works out which items your people actually walk to most, from the picking you have already
done, and finds the ones sitting in the wrong sort of bin.

> **It needs history.** Everything here is measured from finished picks. On a warehouse that has only
> just started using warehouse jobs there is nothing to measure yet, and empty results are the right
> answer rather than a fault.

## Turn slotting on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. Choose the **Slotting** row, then **Next**.
4. Switch on **Enable this feature**, then **Next** and **Finish**.
5. Close the feature list. Your session restarts so the change takes effect.

Directed work must be on as well — both for the picking history slotting reads, and for the movements
it raises when you accept a proposal.

## Choose what counts as fast moving

1. Choose the search icon, enter **Slotting setup**, and choose the related link.
2. **Rank items on** — this is the important one, and **What that means** underneath spells it out:
   - **How often it is picked** — one pick is one trip, whatever was taken. Choose this if the walking
     is the work, which is true in most warehouses.
   - **How much of it is picked** — choose this if the handling is the work, such as a warehouse that
     moves bulk by the pallet.
   The two give genuinely different answers: an item fetched fifty times in ones against an item
   fetched twice by the pallet.
3. **Look back this many days** — how far back an analysis goes. Too short and a seasonal line looks
   dead; too long and a line that stopped selling keeps its good bin.
4. **Fewest picks worth classifying** — an item picked once is not slow moving, it is unmeasured.
5. **Class A percent** and **Class B percent** — the share of all the movement that the fast and the
   medium items account for. Twenty and thirty is the usual starting point.
6. **Class A needs a bin ranked at least** and **Class B needs a bin ranked at least** — the bin
   ranking each class deserves. These are the numbers that decide what gets proposed, so set them
   against the rankings you actually use.

## Work out which items move fastest

1. Choose the search icon, enter **Item velocity**, and choose the related link.
2. **Filter the list to one location.** Velocity compares the items at one site against each other, so
   the app refuses to do it for all of them at once.
3. Choose **Work out velocity**.

You get one line per item: how many times it was picked, how much was picked, which bin it is usually
picked from and that bin's ranking, and its class. Class A is highlighted.

Running it again replaces the previous answer rather than adding to it — a velocity is a statement
about a period.

## Find the items in the wrong bin

Choose **Propose moves** on the same list.

You get a proposal for every classified item picked from a bin worse than its class deserves, saying
which class it is, which bin it is in, that bin's ranking and the ranking it should have.

An item that already has an open proposal does not get a second one, so you can run this every week
without building a pile.

## Answer a proposal

Choose the search icon, enter **Slotting proposals**, and choose the related link.

For each one, either:

- **Fill in Move it to**, then choose **Accept** — the decision is recorded and the job to move the
  goods is raised straight into the warehouse queue; or
- choose **Accept** without filling it in — you have agreed the item should move, and you can choose
  **Raise the move** later once you know where the space is; or
- choose **Reject** — the proposal is kept, because what was suggested and turned down is worth knowing
  next time somebody proposes it again.

**The app does not choose where to move things to.** It does not know which good bins are free, how big
they are, or what else you plan to put in them. It tells you a move is worth making; you say where.

Once a proposal has been answered it cannot be answered again or deleted.

## What slotting does not do yet

- **It does not pick the destination bin**, for the reason above.
- **It only counts picking.** Put-aways, movements and counts are ignored, so an item that is
  replenished constantly but picked rarely looks slow.
- **There is no re-slotting worksheet.** You answer proposals one at a time; nothing plans a whole
  aisle as one operation.
- **It does not know about seasons.** One period, one class — an item that only sells in December is
  class C in June and nothing points that out.
- **A schedule needs one entry per location.** See below — a run has to be told which site it is for,
  so a company analysing three sites needs three job queue entries.

## Have it run by itself

Ask an administrator to create a **job queue entry** for codeunit **WHA Slotting Scheduler**, and to
put a **Location code** filter on it naming the site to analyse. When and how often it runs is set on
the job queue entry, because that is where Business Central keeps schedules.

**The filter is not optional.** Analysing a location replaces everything the app knows about it, so a
run that swept every site would wipe the classes of any warehouse that simply had a quiet period. A
run with no location named refuses and says so. If you analyse more than one site, create one entry
per site.

Each run re-measures the location and then makes its proposals, exactly as **Analyse** and **Propose**
do by hand.

## Load sample data

There is no sample data of its own to load. Switching **Load sample data** on runs the analysis and the
proposals against whatever picking your company has already done — so load the directed work sample
data first if you want something to look at.
