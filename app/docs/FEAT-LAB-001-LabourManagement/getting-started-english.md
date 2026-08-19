# FEAT-LAB-001 - Labour Management

Your warehouse has been recording who did every job, when they started it and when they finished it
ever since you started using warehouse jobs. Labour management reads it: how long the work actually
takes, how that compares with how long you think it should take, and how much of the day is not spent
on jobs at all.

> **Before you switch this on**, decide whether you want individual people measured, and tell them.
> This feature produces performance figures with names on them. That is a decision about how your
> warehouse is run, and no setting in the app makes it for you.

## Turn labour management on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. Choose the **Labour management** row, then **Next**.
4. Switch on **Enable this feature**, then **Next** and **Finish**.
5. Close the feature list. Your session restarts so the change takes effect.

Directed work must be on as well — the whole feature reads finished warehouse jobs.

## Say how long work should take

1. Choose the search icon, enter **Labour standards**, and choose the related link.
2. Choose **New** and fill in:
   - **Task type** — the kind of job the standard covers.
   - **Location code** — leave it blank for a standard that applies everywhere. Fill it in for a site
     that is different, and that standard wins there.
   - **Basis** — how the expected time is worked out. **What that means** below the list spells it
     out:
     - **Per job plus per unit** — an allowance for the job, plus an allowance for each unit handled.
       The usual choice.
     - **Per job only** — the same time whatever was handled. Use this where the quantity is not what
       takes the time, such as moving a whole pallet.
   - **Minutes per job** — the walking, the scanning and the paperwork.
   - **Minutes per unit** — what each unit adds. Ignored on the per-job-only basis.

A standard has to allow *some* time; the app refuses one of zero.

If you stop believing a standard, switch **Blocked** on rather than deleting it. Work is then recorded
with no expected time, instead of being scored against a number you do not trust.

## Turn finished work into recorded time

1. Choose the search icon, enter **Recorded time**, and choose the related link.
2. Choose **Take time from finished work**.

Every finished job that does not already have time against it becomes one line: what it actually took,
what the standard expected, and the two as a percentage. **A hundred percent is exactly to standard,
and more than a hundred is faster than standard.**

Running it again takes nothing extra — a job already counted is never counted twice — so it is safe to
run whenever you like.

To have it run by itself, ask an administrator to create a **job queue entry** for codeunit
**WHA Labour Scheduler**. A **Location code** filter on the entry limits it to one site. When and how
often it runs is set there, because that is where Business Central keeps schedules.

Each run reads the last **Look back over** days of finished work — a month unless you change it in
**Labour setup** — and skips the jobs in it that are already counted. That is what makes it safe to
repeat without getting slower as your history grows.

> **Set the window longer than the gap between runs.** A daily run with a window of one day has no
> margin: work finished on a day the schedule did not run falls outside every later window and is
> never counted. A month of window for a daily run is not wasteful — the run skips what it has
> already done — it is the margin.
>
> Setting it to **zero** reads every job you have ever finished, which is what it used to do. That is
> still correct, and still gets slower for ever.

Two kinds of finished job are skipped rather than guessed at: work that nobody was holding when it
finished, and work that was never properly started.

### When time looks wrong

**Longest believable job** in the setup is the answer to somebody starting a job and going home. Time
longer than that is still recorded — it happened — but it is marked as not measured, so it does not
drag the whole shift's figures down. Set it to zero if you want everything measured.

## Record the time that is not on a job

Breaks, cleaning, briefings, waiting for work, a forklift that would not start. A warehouse where only
the picking is measured looks more productive than it is.

On **Recorded time**, choose **New** and fill in the date, the person, the reason, how long it took and
a description. Leave **Task no.** empty — time with no job against it is recorded as time off the jobs
automatically.

## What to look at

- **Performance percent** per kind of work, rather than per person, tells you which standards are
  wrong. If everybody is at 60% on one task type, the standard is the problem, not the people.
- **Measured** shows what was scored at all. A lot of unmeasured time means missing standards or jobs
  left open.
- The split between time on jobs and time off them is usually the most useful number in here, and the
  one nobody has ever had before.

## What labour management does not do yet

- **It does not know when anybody was supposed to be at work.** There is no shift or rota, so it
  answers how fast the work went, not how busy the day was.
- **It does not cost anything.** Minutes are minutes; nothing turns them into money.
- **Time off the jobs is typed in by hand.** Nothing clocks a break, and there is nothing on the
  handheld — so if people forget, the warehouse looks *better* than it really is.
- **Standards are per kind of job and per location only.** Picking a pallet of bricks and a box of
  envelopes are the same job to this feature.

## Load sample data

Sample standards can be loaded while turning the feature on: switch on **Load sample data** on the same
step as **Enable this feature**. It also turns whatever finished work you already have into recorded
time, so you can see the shape of it immediately.
