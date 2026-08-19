# FEAT-REPL-001 - Replenishment

A pick face that runs empty stops a pick round. Replenishment watches the bins your people pick from
and raises the work to top them up before anybody finds them empty.

You write a rule per bin: how low it may run, and how full to fill it. Then you run replenishment —
by hand, or on a schedule — and the work appears in the ordinary job queue.

## Turn replenishment on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. Choose the **Replenishment** row, then **Next**.
4. Switch on **Enable this feature**, then **Next** and **Finish**.
5. Close the feature list. Your session restarts so the change takes effect.

Directed work must be on as well. Replenishment does not move anything itself — it raises warehouse
jobs, and somebody has to be able to see them.

## Choose how replenishment behaves

1. Choose the search icon, enter **Replenishment setup**, and choose the related link.
2. **Default method** — where a new rule takes its measurement from:
   - **Bin content** is what Business Central believes is in the bin. Use this if your movements are
     posted as they happen.
   - **Handling units** is what the pallets standing in the bin say they hold. Use this if you work
     with pallet or container IDs and the posting follows later.
3. **Default priority for replenishment work** — how urgent the raised jobs are compared with
   everything else in the queue. A lower number is more urgent.
4. **Measure a bin against** — whether a run looks ahead:
   - **What is in the bin now** is what a new installation starts on. A run reads the shelf and
     nothing else.
   - **What is in the bin less what is already promised** takes off the picks that are planned but
     not yet walked. A pick face with a hundred in it and ninety already promised counts as ten. This
     is usually the setting you want once your picks are planned rather than typed as they happen.
   - **What is in the bin less what one wave will take** is for pre-replenishing a single wave — see
     below.

   **What that takes into account** underneath spells out the choice in full before you save it.
5. **Send replenishment work to the floor** — leave this on so a run puts the work straight into the
   queue. Switch it off if you want to look at what a run proposed before anybody is sent to do it;
   the jobs are then created as drafts and you release them yourself.

## Write a rule

1. Choose the search icon, enter **Replenishment rules**, and choose the related link.
2. Choose **New**.
3. Fill in the **Location code**, the **Bin code** of the bin you are keeping stocked — the bin people
   pick *from* — and the **Item no.**
4. Fill in **Minimum quantity**: how low that bin may run before it is topped up.
5. Fill in **Maximum quantity**: how full it is filled back to.
6. Optionally set the **Source bin code** — the bulk bin the goods are fetched from. Leave it blank to
   let whoever does the work decide where to take them from.
7. Set **Priority** if this bin should be more or less urgent than your default.

Each bin and item can have one rule, so you cannot write two rules that disagree about the same bin.

> A **minimum of zero never asks for anything**. That is how you write a rule down without acting on
> it yet.

## See what a rule would do, before it does it

Open the rule. **In the bin now** is what the rule measures at this moment, **Already promised** is
how much of that is spoken for by work somebody has planned but nobody has walked yet, **Would ask
for** is what a run would raise right now, and **Where the measurement comes from** says which of the
two measurements you are looking at.

**Already promised** reads zero unless your setup says to take planned work into account.

If **In the bin now** does not match what you can see in the aisle, the method is the first thing to
check, and the unit of measure is the second.

**You can write a rule in any unit.** A rule in pallets is measured in pallets even when the stock is
held as loose pieces, and a bin holding both a pallet and some loose pieces is added up correctly
rather than treated as two of something. That relies on the item having a pieces-per-pallet conversion
set up — see below.

## Run replenishment

Choose **Replenish now** — on a single rule, or on the rule list to do every rule at once. You are
told how many jobs were raised.

The work appears wherever your warehouse jobs appear, including on the handheld.

**Running it twice does not raise the work twice.** A bin that already has replenishment work
outstanding is left alone, so it is safe to run this every few minutes. Once that job is finished or
withdrawn, the bin can ask again.

### Have it run by itself

Ask an administrator to create a **job queue entry** for codeunit **WHA Repl. Scheduler**. When and how
often it runs is set on the job queue entry, because that is where Business Central keeps schedules.
Put a **Location code** filter on the entry to limit it to one part of the warehouse.

### Fill the pick faces a wave is about to need

Open a wave and choose **Replenish for this wave**. It looks at what that wave's picks will draw from
each pick face, and fills the ones that will run out — before the wave goes out rather than after it
has stalled halfway through.

It looks at **that wave only**. Work planned for other days is deliberately not counted, or the pick
face would be filled for work that is not going out yet.

The jobs it raises name the wave, so whoever picks one up can see what is waiting on it. A wave that
is already finished or cancelled cannot be pre-replenished, and you are told so rather than left with
a run that quietly did nothing.

## Stop a rule without deleting it

Switch on **Blocked**. Runs skip the rule, and what it says is kept for when the line comes back.

## What replenishment does not do

It does not move stock — it raises the job, and the stock moves when somebody does the job.

It does not check that the bin it fetches *from* has anything in it. If it is empty too, the operator
reports the job short, and you will see it as a short job in the usual place.

Nothing reserves the stock a run has just filled a bin with, so two runs very close together against
a fast-moving bin can both decide it needs work. The second one will not raise a duplicate job, but
nothing is held against a promise.

It assumes a pick that does not say which bin it is coming from is coming from the pick face. That is
right in almost every warehouse and wrong if you pick the same item from several faces at one
location — nothing detects that.

Releasing a wave does not replenish for it. Somebody chooses **Replenish for this wave**, or the
scheduled run catches it.

If you write a rule in a unit you have not set up for that item — a pallet with no pieces-per-pallet on
record — the rule is measured in the item's base unit instead, and nothing warns you. Check **In the
bin now** against the aisle when you first write a rule in anything other than the base unit.

## Load sample data

Sample rules can be loaded while turning the feature on: switch on **Load sample data** on the same
step as **Enable this feature**. They are written against the first bins the app finds, so treat them
as examples of the shape of a rule rather than as anything to run.
