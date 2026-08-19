# FEAT-WAVE-001 - Wave Management

A wave is a batch of warehouse work that goes to the floor together — everything for the four
o'clock lorry, or everything for the morning round. Instead of jobs trickling out one at a time, you
gather them, send them out at once, and see the batch finish as a batch.

## Turn wave management on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Wave management** row, then **Next**.
4. Switch on **Enable this feature**, leave **Create and assign number series** on, then **Next** and
   **Finish**. Waves are numbered from a series this step creates for you.
5. Close the feature list. Your session restarts so the change takes effect.

Directed work must be on as well — a wave gathers warehouse tasks, so without them there is nothing
to gather.

## Choose how waves are built

1. Choose the search icon, enter **Wave setup**, and choose the related link.
2. **Default strategy** — how a new wave decides which work to gather:
   - **Most urgent first** takes the work the warehouse would have done next anyway.
   - **Due first** takes whatever is needed soonest, whatever its priority. Use this if you work to
     departure times.
3. **Default max jobs per wave** — how many jobs a wave takes when you fill it. Start smaller than
   you think: a wave nobody can finish in a shift is a wave nobody trusts.
4. **Gather work that is not released yet** — leave this off if somebody should approve work before
   it can be put in a wave. Switch it on if the wave *is* the approval, in which case releasing the
   wave is what sends its jobs to the floor.

## Build the same wave every day

Typing the same wave every morning is how the settings drift. A **wave template** is that wave written
down once.

1. Choose the search icon, enter **Wave templates**, and choose the related link.
2. Choose **New** and give it a **Code** and a **Description** — the description is what every wave it
   builds is called.
3. Choose the **Location code**, the **Strategy**, and how much work a wave should take:
   - **Max jobs** — how many jobs, as before.
   - **Max minutes of work** — how much *work*, which is usually the better question. It only does
     something once somebody has written labour standards; until then leave it at zero.
4. **Release the wave when it is built** — leave this off if somebody should look at what was gathered
   before it goes to the floor.
5. **What that builds** underneath spells out what you have set up, as one sentence.

Choose **Build a wave** to run it now. You are told which wave was built and how much it gathered. If
there was nothing to gather, **no wave is created** — an empty wave every morning is just noise.

### Run it on a schedule

Tick **Include in the scheduled run** on the templates that should run unattended, then ask an
administrator to create a **job queue entry** for codeunit **WHA Wave Scheduler**. When and how often
it runs is set on the job queue entry, because that is where Business Central keeps schedules — this
feature does not have its own timetable to fall out of step with it.

**Run the scheduled templates** on the template list does the same thing by hand, so you can see what
the schedule will do before you set it up.

### Finishing with a template

Tick **Blocked**. A blocked template builds nothing, by hand or on a schedule. **You cannot delete a
template that has built waves** — those waves name it, and deleting it would leave them pointing at
nothing.

## Create and fill a wave

1. Choose the search icon, enter **Waves**, and choose the related link.
2. Choose **New**. The **No.** fills in automatically.
3. Fill in **Description** — what this wave is for, such as *Afternoon departure*.
4. Choose the **Location code**. A wave only gathers work from one part of the warehouse.
5. Choose a **Strategy** if this wave should work differently from your default. **What it gathers**
   tells you what that strategy picks before you use it.
6. Set **Max jobs** if this wave should be bigger or smaller than usual.
7. Choose **Fill**. You are told how many jobs were gathered.

Fill again at any time while the wave is open and it tops up to its maximum.

Choose **Jobs in this wave** to see exactly what you have gathered — and to check it looks like a
sensible round of work before anyone is sent to do it.

## Send it to the floor

Choose **Release**.

Every job in the wave becomes available to operators at once. That is the whole point of a wave: the
work starts together.

A wave with no jobs cannot be released, and once a wave is released you cannot add to it or take
from it — people are already working it.

## Watch it finish

**Jobs** and **Jobs finished** on the wave show progress. Jobs that were cancelled count as
finished, because they are no longer outstanding.

**Nothing closes a wave by itself.** When you want the list to be up to date, choose **Close
finished waves** on the wave list — every released wave whose work is done is closed. An
administrator can also have this run automatically on a schedule.

You can also close a single wave with **Complete** on the wave itself. If any of its work is still
outstanding you are told how much.

## Withdraw a wave

Choose **Cancel**. Any job in the wave that nobody has started is withdrawn with it. Jobs already in
progress are left alone — somebody is holding them.

An open wave can be deleted, and its jobs simply go back to being ordinary work. A wave that has
been released cannot be deleted: cancel it instead, so the record of what was planned survives.

## Load sample data

Sample waves — one being built, one released, one never used — can be loaded while turning the
feature on. Switch on **Load sample data** on the same step as **Enable this feature**. Load the
directed work sample data first, or there is no work for the sample waves to gather.

A sample template, **DEMO-MORNING**, is loaded with them. It is deliberately **not** marked for the
scheduled run, so it will not start building waves by itself if you later set up a job queue entry.

## How much work is in a wave

Open a wave and look at **Minutes of work gathered**. It is worked out from your labour standards —
what each kind of job at that location is expected to take — so it answers the question a job count
cannot: is this a shift's worth?

**Measured by a standard** tells you whether to believe it. If it is off, nobody has written a
standard for this work, the minutes read zero, and the wave is limited by its job count alone. Zero
minutes because nothing measured the work is not the same as no work.

If a wave has **Max minutes of work** set, filling stops once it has that much. One exception: if the
very first job on its own takes longer than the whole allowance, it is still taken — otherwise a long
job would never be gathered by any wave and would sit on the queue for ever.

## What is not here yet

A wave now knows how much work it holds, but nothing **balances** that work across your operators —
the app does not know who is on shift or what they are already carrying. Nothing warns you that a
template has stopped producing waves; if its location was renamed or its strategy no longer matches
anything, it quietly finds nothing every morning and you have to notice. The scheduled run is all or
nothing per template — there is no "weekdays only". Operators are still not told which wave their job
came from.
