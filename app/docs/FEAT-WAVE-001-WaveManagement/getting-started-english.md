# FEAT-WAVE-001 - Wave Management

A wave is a batch of warehouse work that goes to the floor together — everything for the four
o'clock lorry, or everything for the morning round. Instead of jobs trickling out one at a time, you
gather them, send them out at once, and see the batch finish as a batch.

## Turn wave management on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Foundation** row and make sure **Create and assign number
   series** is on. Waves are numbered from a series created there.
4. Back in the feature list, choose the **Wave management** row, then **Next**.
5. Switch on **Enable this feature**, then **Next** and **Finish**.
6. Close the feature list. Your session restarts so the change takes effect.

Directed work must be on as well — a wave gathers warehouse tasks, so without them there is nothing
to gather.

> If you set the app up before waves were added, the **Foundation** row shows as **Not started**
> again, because it now creates a third number series. Run it once more; nothing you already set up
> is changed.

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

## What is not here yet

There are no wave templates: you create each wave by hand, and nothing runs "every morning at six".
Nothing balances a wave across your operators or tells you whether a wave is a shift's worth of
work — **Max jobs** counts jobs, and jobs are not all the same size. Operators are not told which
wave their job came from.
