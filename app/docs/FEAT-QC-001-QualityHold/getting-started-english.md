# FEAT-QC-001 - Quality Hold

Somebody finds a problem with goods that are already in the warehouse — a pallet arrives damaged, a
line is waiting for inspection, a customer sends something back. Put it on hold and nobody can be sent
to fetch it, pack it or pick from it until you have decided what happens to it.

Holding a pallet holds everything on it, and every hold is kept for ever: who stopped the goods, why,
who let them go again, and what was decided.

> **Read this before you start.** Quality hold stops goods being *used*. It does not change what you
> own: scrapping a pallet here does not write it off in your inventory. Do that the way you do today.

## Turn quality hold on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. Choose the **Quality hold** row, then **Next**.
4. Switch on **Enable this feature**, then **Next** and **Finish**.
5. Close the feature list. Your session restarts so the change takes effect.

Handling units must be on as well — a hold is placed on a pallet, cage or carton.

## Choose how holds behave

1. Choose the search icon, enter **Quality hold setup**, and choose the related link.
2. **Default reason** — what a hold is given when somebody stops goods without picking a reason. They
   can change it afterwards.
3. **Hold what is inside as well** — leave this on. A pallet nobody may touch whose cartons can still
   be picked is not on hold.
4. **Decide before releasing** — leave this on, so goods cannot go back into stock until somebody has
   said what happens to them.

## Stop some goods

1. Choose the search icon, enter **Handling units**, and choose the related link.
2. Open the pallet, cage or carton.
3. Choose **Put on hold**. You are told which hold was created.

Straight away:

- nobody can be given a job that moves it,
- nothing can be added to it or taken out of it,
- it cannot be packed,
- and if you use replenishment, its contents stop counting as stock you can pick.

Everything nested inside it is held too, each with its own hold record, so you can see exactly what was
stopped.

You cannot hold goods that have already shipped, and you cannot put a second hold on something that is
already held.

## Say what happens to the goods

1. Choose the search icon, enter **Quality holds**, and choose the related link, or choose **Quality
   holds** on the handling unit.
2. Open the hold and fill in **Reason** and **Description** — what you found, in your own words.
3. Choose a **Disposition**. **What that means** tells you what each choice does before you commit to
   it:
   - **Release back into stock** — the goods are fine. The unit goes back to exactly what it was.
   - **Rework** — the goods can be put right. The unit is opened so its contents can be worked on.
   - **Scrap** — the goods are written off. The unit is marked as scrapped and never comes back into
     use.

You can change your mind as often as you like while the hold is on.

## Let the goods go

Choose **Release** on the hold.

The decision is carried out — on this unit and on everything that was held with it — and the hold
records who lifted it and when.

**A hold with no decision cannot be released.** That is deliberate: a hold lifted without anybody
deciding anything puts the goods straight back into stock, which is what you were trying to prevent.

Release the **outer** unit: releasing a carton on its own while the pallet under it is still on hold is
refused, and you are told which hold to release instead.

## Look back at what was held

The hold list shows every hold ever placed, newest first. **Show what is still on hold** narrows it to
the goods that are still stopped — the list somebody has to work through — and **Show everything**
brings the history back.

Holds cannot be deleted, ever. That is the point of them.

## What quality hold does not do yet

- **It does not write anything off.** Scrapping marks the unit and leaves your inventory figures alone.
- **You can only hold a handling unit** — not an item, not a lot, not a bin. To quarantine every pallet
  of a bad lot you have to hold each one.
- **You cannot put goods on hold from the handheld.** The person who finds the damage has to ask
  somebody at a desk, which is the wrong way round and is known.
- **Nothing chases you.** No reminder that goods have been sitting on hold for three weeks.

## Load sample data

Sample holds can be loaded while turning the feature on: switch on **Load sample data** on the same
step as **Enable this feature**. Load the handling unit sample data first, because the holds are placed
on those pallets. You get one damaged pallet still waiting for a decision — which shows the carton on
it being held too — and one cage that was held, checked and released.
