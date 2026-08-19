# FEAT-QC-001 - Quality Hold

Somebody finds a problem with goods that are already in the warehouse — a pallet arrives damaged, a
line is waiting for inspection, a customer sends something back. Put it on hold and nobody can be sent
to fetch it, pack it or pick from it until you have decided what happens to it.

Holding a pallet holds everything on it, and every hold is kept for ever: who stopped the goods, why,
who let them go again, and what was decided.

> **Read this before you start.** Quality hold stops goods being *used*. It can also write scrapped
> goods off your inventory, and out of the box it does not — see *Decide what scrapping should do*.
> Until you set that, scrapping a pallet marks it as finished with here and leaves your inventory
> figures alone.

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

## Decide what scrapping should do

This is the setting that decides whether scrapping goods takes them off your inventory, and it is
worth agreeing with whoever owns your stock figures before you change it.

On **Quality hold setup**, under **Writing off scrapped goods**, choose one of three under **Write
scrapped goods off by**. **What that does** underneath spells out what you have chosen, in full,
before you save it.

- **Do not post** — what a new installation starts on. Scrapping marks the pallet as finished with and
  leaves your inventory alone. Choose this if somebody else writes goods off, or while you are still
  getting used to the feature.
- **Put the lines in an item journal** — scrapping writes the goods into an item journal batch you
  choose and stops there. Somebody opens that journal, checks it, and posts it.
- **Post to the item ledger** — scrapping takes the goods off your inventory there and then.

If you choose the journal option, fill in **Item journal template name** and **Item journal batch
name** as well; releasing a scrap will refuse if there is nowhere to put the lines.

**Posting reason code** is optional and worth setting: it marks every write-off a quality decision
raises, so you can tell them apart from every other correction in your ledger.

Only **Scrap** writes anything off. Releasing goods back into stock and sending them for rework never
touch your inventory.

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
   - **Scrap** — the goods are finished with. The unit is marked as scrapped and never comes back into
     use, and your inventory figures change if you have set them to.

You can change your mind as often as you like while the hold is on.

## Let the goods go

Choose **Release** on the hold.

The decision is carried out — on this unit and on everything that was held with it — and the hold
records who lifted it and when.

If the decision was **Scrap** and you have set scrapping to write goods off, that happens now. Under
**What was written off** the hold tells you what it did: **Posted** is ticked only when your inventory
has actually changed, **Posted quantity** is how much went, and **Posting document no.** is the
reference to look up. Each unit that was held writes off its own contents under its own document, so a
pallet and the carton on it appear separately.

If something stops the write-off being made — a blocked item, a closed period, a missing permission —
**the hold is not released**. Fix what it complains about and release it again.

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

- **A release cannot be undone.** Once a hold is lifted it stays lifted, and a write-off made by
  mistake is corrected in Business Central rather than here.
- **Rework is not accounted for.** Goods sent for rework are not written off, and nothing notices if
  less comes back than went in.
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
