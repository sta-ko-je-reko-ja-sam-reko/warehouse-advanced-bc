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
4. **Send replenishment work to the floor** — leave this on so a run puts the work straight into the
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

Open the rule. **In the bin now** is what the rule measures at this moment, **Would ask for** is what
a run would raise right now, and **Where the measurement comes from** says which of the two numbers
you are looking at.

If **In the bin now** does not match what you can see in the aisle, the method is the first thing to
check.

## Run replenishment

Choose **Replenish now** — on a single rule, or on the rule list to do every rule at once. You are
told how many jobs were raised.

The work appears wherever your warehouse jobs appear, including on the handheld.

**Running it twice does not raise the work twice.** A bin that already has replenishment work
outstanding is left alone, so it is safe to run this every few minutes. Once that job is finished or
withdrawn, the bin can ask again.

Ask an administrator to schedule the run if you want it to happen by itself. Nothing runs it for you.

## Stop a rule without deleting it

Switch on **Blocked**. Runs skip the rule, and what it says is kept for when the line comes back.

## What replenishment does not do

It does not move stock — it raises the job, and the stock moves when somebody does the job.

It does not check that the bin it fetches *from* has anything in it. If it is empty too, the operator
reports the job short, and you will see it as a short job in the usual place.

It does not look ahead at what today's orders or a released wave are about to need. Every rule is
about the level in the bin right now.

It assumes the minimum, the maximum and the measurement are all in the same unit. If you keep the bin
in pallets but the system counts pieces, the rule will be wrong and nothing will warn you.

## Load sample data

Sample rules can be loaded while turning the feature on: switch on **Load sample data** on the same
step as **Enable this feature**. They are written against the first bins the app finds, so treat them
as examples of the shape of a rule rather than as anything to run.
