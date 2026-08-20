# FEAT-TASK-001 - Directed Work

Directed work turns warehouse jobs into a queue. Each job is a task with a priority, so the most
urgent work is handed to whoever asks for something to do next — and you can see who is doing what,
and when each job was started and finished.

## Turn directed work on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Directed work** row.
4. Read the introduction, then choose **Next**.
5. Switch on **Enable this feature**, and leave **Create and assign number series** on — warehouse
   jobs are numbered from a series this step creates for you. Choose **Next** and **Finish**.
6. You return to the feature list, where **Directed work** now shows as **Completed**.
7. Close the feature list. Your session restarts so the change takes effect. This takes a few
   seconds and you do not need to sign in again.

After the restart, **Warehouse tasks** is available from the search.

## Choose how the queue behaves

1. Choose the search icon, enter **Warehouse task setup**, and choose the related link.
2. Set **Default priority** — the urgency a task gets when nobody chooses one. A **lower** number is
   more urgent, so leaving room above and below the default is useful.
3. Switch **Release tasks automatically** on if work should go to the floor as soon as it is
   created. Leave it off if someone should review tasks first. A task that does not yet say where
   the work is, or what is being moved, is never released automatically.
4. Set **Max open tasks per user** if one person should only hold a few jobs at a time. Leave it at
   zero for no limit.

## Load sample data

If you want something to look at before entering your own work, you can load a small set of example
tasks covering each kind of job and each stage of the life cycle.

You are offered this while turning the feature on — switch on **Load sample data** on the same step
as **Enable this feature**.

- The examples are created in the company you are working in.
- It is safe to run more than once. Nothing is duplicated.
- The examples use the locations, bins and items your company already has. On an empty company you
  get the tasks without them.
- The examples are for trying things out. Review them before relying on them in a company you use
  for real work.
- An administrator also gets a **configuration package** for warehouse tasks, which can be copied
  into other companies.

## Raise work from goods that have arrived or are due to leave

This is usually where work should come from, rather than from typing.

1. Open a **warehouse receipt** (goods that have arrived) or a **warehouse shipment** (goods due to
   leave).
2. Choose **Create warehouse tasks**.
3. You are told how many jobs were put on the queue — one for every line that still has something
   outstanding on it.

A receipt raises **put-aways**, each starting in the bin the receipt names. A shipment raises
**picks**, each ending in the bin the shipment names. The other bin is deliberately left empty: where
goods should be put, and where they should be taken from, depends on your stock and your warehouse
layout, and the document cannot know it. The person doing the job fills it in.

**It is safe to press again.** Lines that already have a job are skipped, so pressing it a second
time, or after adding a line to the document, only raises what is missing. If everything is already
covered you are told that too.

If you cancelled a job by mistake, press the button again — a cancelled job leaves its line
uncovered, so the document will raise it afresh.

**Nothing happens by itself.** Releasing or posting a receipt or shipment does not create work; a
person presses the button. That is deliberate until it is confirmed how your warehouse actually
receives and ships.

## Create a task by hand

1. Choose the search icon, enter **Warehouse tasks**, and choose the related link.
2. Choose **New**.
3. The **No.** field fills in automatically.
4. Choose the **Task type** — put-away, pick, movement, replenishment or count.
5. Fill in **Description** so the person doing the job knows what is being asked.
6. Choose the **Location code**, then the **From bin code** and **To bin code** if the job moves
   goods between bins.
7. Say what is being moved, in one of two ways:
   - Choose a **Handling unit no.** if a whole pallet, cage or carton is being moved. The location
     and bin of the unit fill in for you.
   - Or choose an **Item no.** and enter a **Quantity**.
8. Set **Priority**. A lower number is more urgent. If you leave it, the default from the setup is
   used.
9. Set a **Due date** if the work is needed by a particular day. Tasks of the same priority are
   offered oldest-due first.

> Changing the **Location code** clears both bins, because a bin belongs to one location. Choose the
> bins again after you change the location.

> You cannot create work for a handling unit that has already been shipped.

## Send a task to the floor

Open the task and choose **Release**.

Until a task is released it is a draft: it does not appear to anyone asking for work. A task cannot
be released until it says both **where** the work happens and **what** is being moved.

## Do the work

The person doing the job works from the **Warehouse tasks** list:

1. Choose **Get next task**.
2. The most urgent released task is opened and assigned to you.
3. Choose **Start** when you begin.
4. Choose **Complete** when the job is done.

**Get next task** gives you back your own unfinished work first — anything you had already started,
then anything already assigned to you — before it hands you something new. So a job you were pulled
away from is not lost.

If there is nothing waiting, you are told so.

Choose **My tasks** to see only your own work, and **All tasks** to clear that filter again.

> Completing a task that names a handling unit records that unit in the **To bin code** you were
> sent to, so the unit's own page shows where it now is.

## Hand work to someone else

- To take a job yourself, open it and choose **Assign to me**.
- To give it to someone else, open it and choose a person in **Assigned to user ID**.
- To hand a job back, clear **Assigned to user ID**. The task returns to the queue for anyone to
  pick up.

You cannot hand over work that is already in progress. The person doing it must hand it back first,
so nobody loses track of a half-finished job.

If **Max open tasks per user** is set, you are told when someone already has as many jobs as they
are allowed.

## When there is less than the job asked for

An operator who is sent for twelve and finds four reports the job **short** rather than finishing it
in full. The job closes with what was actually moved and a reason why the rest is missing.

- **Quantity** stays as what was asked for. **Quantity handled** shows what was really moved, and
  **Short reason** says why.
- Finding *nothing at all* is still worth reporting. It closes the job and tells you the bin is
  empty, instead of sending the next person to the same place.
- A job that moves a whole handling unit cannot be short — there is no half a pallet. Hand it back
  instead.

By default nobody is sent back for the missing eight; the shortfall is reported and you decide. If
you would rather the app raised a new job for whatever was not found, switch on **Raise a follow-up
for short picks** in the warehouse task setup. The follow-up is created as a draft, so somebody
looks at it before anyone walks to the same bin again.

## Follow what happened

Each task records the time it moved through the life cycle:

- **Assigned at** — when it was given to someone.
- **Started at** — when they began.
- **Completed at** — when they finished.

**Quantity handled** and **Short reason** show whether the job was done in full.

**Status** shows where a task is now: **Created**, **Released**, **Assigned**, **In progress**,
**Completed** or **Cancelled**. You cannot type over it — it changes through the actions above, so
the times always match what really happened.

## See where a job came from

Open a task and look at **Where the work came from**:

- **Source type** — whether it was raised from a receipt, from a shipment, or typed by hand.
- **Document** — the document and line it came from, named in full.
- **Source document no.** — the purchase or sales order behind it, which is what tells you who is
  actually waiting.
- **Still wanted** — whether the line it came from still has something outstanding. If this says no,
  the goods have been received or shipped some other way and the job is a walk for nothing. Cancel
  it.

**Source document** opens the receipt or shipment itself.

Nothing warns you about a job that is no longer wanted, and nothing cancels one for you — you have to
look.

## Withdraw a task

Open the task and choose **Cancel**. The task stays in the list as a record of what was asked for.

A task that has been started or completed cannot be deleted at all. Cancel the ones you no longer
want, and delete only drafts that never went anywhere.

## Let finished work fill in the document

Off unless you turn it on, and worth understanding before you do.

1. Choose the search icon, enter **Warehouse task setup**, and choose the related link.
2. Switch on **Write back to the document**.

From then on, finishing a job fills in **Qty. to Receive** on the warehouse receipt, or **Qty. to
Ship** on the warehouse shipment, with what was actually handled. Nobody has to retype it, and the
document is ready to post when the work on the floor is done.

Two things to know:

- **It adds up.** A job finished short raises a follow-up; when that one finishes too, the document
  holds the total of both, not just the last.
- **It never asks for more than the line wants.** If a job somehow moved more than the line is
  waiting for, the document gets what the line is waiting for.

Leave it off and nothing changes: the document stays exactly as it was, and somebody fills in the
quantities the way they do today.

## Let finished work move the stock in Business Central

Off unless you turn it on, and the biggest of the three switches on this page.

1. Choose the search icon, enter **Warehouse task setup**, and choose the related link.
2. Set **Warehouse registration method** to **Register a warehouse movement**.

The line underneath the field tells you what the choice you are looking at does. Read it before you
change it.

With it off, finishing a job moves the pallet in the warehouse app and nothing else. Business Central
still believes the goods are in the bin they left, and somebody keeps the two in step by hand.

With it on, finishing a job registers a warehouse movement in Business Central. **Bin content** and
**warehouse entries** follow the floor, so a bin content enquiry, an availability check and a
physical inventory all see what the operator actually did.

Three things to know:

- **It only applies where Business Central keeps bins.** At a location that is not bin mandatory
  there is nothing to record, and finishing a job behaves exactly as it did before.
- **A job needs two bins.** Work that takes from a bin and puts into another bin is a movement. A pick
  that ends at a shipment, or a put-away of goods that have just arrived, is not — that stock is
  accounted for when the document is posted.
- **Business Central can refuse.** If the bin does not hold what the job says it moved, the movement
  is rejected and the job does not finish. That is deliberate: it stops the two records drifting apart
  silently.

## Before you use this at a location with bins

Business Central has a warehouse of its own, and two of its location settings clash with this app.

1. Choose the search icon, enter **Locations**, and open the location you will work at.
2. Make sure **Require Receive** and **Require Shipment** are **on** — this app raises work from
   warehouse receipts and warehouse shipments, and without them there are none.
3. Make sure **Require Put-away** and **Require Pick** are **off**.

If you leave those last two on, Business Central creates its own put-away and pick documents for the
same goods, and an operator gets sent to the same bin twice. The app will not let that happen: raising
work from a receipt or shipment at such a location stops with a message naming the location.

**A location with Directed Put-away and Pick cannot be used for this feature at all.** Business Central
turns all four settings on with it and will not let them off. Counting, quality hold and their posting
still work at such a location.

## Let only warehouse employees be given work

Off unless you turn it on.

1. Choose the search icon, enter **Warehouse task setup**, and choose the related link.
2. Set **Who may be given work** to **Only warehouse employees at that location**.

Business Central keeps a list of who works in which warehouse, on the **Warehouse Employees** page. With
this on, a job can only be given to somebody on that list for the location the job happens at — the same
rule Business Central''s own warehouse pages follow. Anybody else is refused, with a message saying who
and where.

Leave it as it is and the list is not consulted: anybody who can reach the tasks can be given one.

Turning it on does not revisit work somebody already holds. Only jobs assigned from then on are checked.

## Hold a document until its work is finished

Off unless you turn it on.

1. Choose the search icon, enter **Warehouse task setup**, and choose the related link.
2. Set **Open work on posting** to **Hold the document until the work is finished**.

From then on, posting a warehouse receipt or shipment stops if jobs raised from it are still open, and
the message says how many. Finish them, or cancel the ones nobody needs, and the document posts.

Leave it as it is and nothing changes: the document posts whenever somebody posts it, whatever the floor
is still doing.

## What is not here yet

Nothing **warns** you while work is still open. If you have turned on **Open work on posting**, the first anybody hears about it is the refusal when they try to post.

Only warehouse receipts and warehouse shipments raise work. Internal put-aways, movement worksheets,
production and assembly do not.

Registering a warehouse movement does not touch **item tracking beyond the lot or serial already on
the pallet**, and it does nothing about expiry dates. It also does not move goods between locations —
that is a transfer, and this app does not raise one.

Nothing yet plans a route around the warehouse or combines a pick and a put-away into one trip. There
is no handheld screen for the floor; that comes with the mobile device feature.
