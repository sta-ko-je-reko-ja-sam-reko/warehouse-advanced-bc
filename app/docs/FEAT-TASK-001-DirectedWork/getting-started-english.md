# FEAT-TASK-001 - Directed Work

Directed work turns warehouse jobs into a queue. Each job is a task with a priority, so the most
urgent work is handed to whoever asks for something to do next — and you can see who is doing what,
and when each job was started and finished.

## Turn directed work on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Foundation** row, and make sure **Create and assign number
   series** is switched on. Warehouse tasks are numbered from a series created here.
4. Back in the list of features, choose the **Directed work** row.
5. Read the introduction, then choose **Next**.
6. Switch on **Enable this feature**, then choose **Next** and **Finish**.
7. You return to the feature list, where **Directed work** now shows as **Completed**.
8. Close the feature list. Your session restarts so the change takes effect. This takes a few
   seconds and you do not need to sign in again.

After the restart, **Warehouse tasks** is available from the search.

> If you turned the app on before directed work was added, the **Foundation** row shows as **Not
> started** again. That is because it now creates a second number series. Run it once more — nothing
> you already set up is changed.

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

## Create a task

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

## Follow what happened

Each task records the time it moved through the life cycle:

- **Assigned at** — when it was given to someone.
- **Started at** — when they began.
- **Completed at** — when they finished.

**Status** shows where a task is now: **Created**, **Released**, **Assigned**, **In progress**,
**Completed** or **Cancelled**. You cannot type over it — it changes through the actions above, so
the times always match what really happened.

## Withdraw a task

Open the task and choose **Cancel**. The task stays in the list as a record of what was asked for.

A task that has been started or completed cannot be deleted at all. Cancel the ones you no longer
want, and delete only drafts that never went anywhere.

## What is not here yet

Warehouse tasks are not created automatically from receipts, shipments or worksheets — you enter
them, or another system creates them. Nothing yet plans a route around the warehouse or combines a
pick and a put-away into one trip. There is no handheld screen for the floor; that comes with the
mobile device feature.
