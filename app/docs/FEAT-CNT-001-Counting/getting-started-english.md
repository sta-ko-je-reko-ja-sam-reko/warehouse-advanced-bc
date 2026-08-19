# FEAT-CNT-001 - Counting

Counting a slice of the warehouse while the rest of it keeps working, instead of stopping everything
once a year. You say what to count, somebody counts it without seeing what was expected, and anything
that comes out wrong by more than you allow has to be looked at before the count is closed.

> **Read this before you start.** Counting can now correct your inventory, and out of the box it does
> not. Closing a count sheet changes what Business Central believes you have **only if you tell it
> to** — see *Decide what closing a sheet should do*. Until you do, counting measures and reports, and
> you correct the figures the way you do today.

## Turn counting on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. Choose the **Counting** row, then **Next**.
4. Switch on **Enable this feature**, leave **Create and assign number series** on, then **Next** and
   **Finish**. Count sheets are numbered from a series this step creates for you.
5. Close the feature list. Your session restarts so the change takes effect.

## Choose how counting behaves

1. Choose the search icon, enter **Counting setup**, and choose the related link.
2. **Default selection** — what a new sheet gathers when you fill it:
   - **Bins** takes everything Business Central believes is in a bin at that location.
   - **Handling units** takes everything the pallets standing there say they hold. Use this if you
     want to know whether a pallet holds what its label claims.
3. **Count blind** — leave this on. The person counting does not see what was expected until the sheet
   has been counted. A counter who can see the expected number tends to write it down.
4. **Tolerance quantity** and **Tolerance percent** — how far a count may differ before somebody has
   to look at it. A line passes if it is inside *either* one, so set the one that fits how you count:
   a flat number for small quantities, a percentage for loose goods. Both zero means every difference,
   however small, needs a decision.
5. **Approve differences above tolerance** — leave this on so a sheet cannot be closed with a
   difference nobody has looked at.

## Decide what closing a sheet should do

This is the setting that decides whether counting corrects your stock, and it is worth agreeing with
whoever owns your inventory figures before you change it.

On **Counting setup**, under **Posting**, choose one of three under **Post differences by**. **What
that does** underneath spells out what you have chosen, in full, before you save it.

- **Do not post** — what a new installation starts on. Closing a sheet records the difference and
  changes nothing else. Choose this if your finance team will not have the warehouse writing to the
  ledger, or while you are still getting used to counting.
- **Put the lines in an item journal** — closing a sheet writes the differences into an item journal
  batch you choose and stops there. Somebody opens that journal, looks at what the warehouse found,
  and posts it. This is the middle ground, and it is the one most warehouses want first.
- **Post to the item ledger** — closing a sheet corrects your stock there and then. Nothing is left
  for anyone to check afterwards.

If you choose the journal option, fill in **Item journal template name** and **Item journal batch
name** as well; closing a sheet will refuse if there is nowhere to put the lines.

**Posting reason code** is optional and worth setting: it marks every adjustment a count raises, so
you can tell counting differences apart from every other correction in your ledger.

Whoever closes count sheets needs permission to post item journals. If they do not have it, closing
fails and nothing is changed.

## Count something

### 1. Make a sheet

1. Choose the search icon, enter **Count sheets**, and choose the related link.
2. Choose **New**. The **No.** fills in automatically.
3. Fill in **Description** — what this count covers, such as *Aisle A, Tuesday*.
4. Choose the **Location code**.
5. Check the **Posting date**. This is the date any correction the sheet raises is dated — the date
   the count applies to, which is not necessarily the day you get round to closing it. It starts as
   your working date and you can change it until the sheet is closed.
6. Choose a **Selection** if this sheet should gather something different from your default. **What it
   gathers** tells you what that means before you use it.
7. Choose **Fill**. You are told how many lines were put on the sheet.

Add or remove lines by hand while the sheet is open, if you want to count something narrower.

### 2. Send it out

Choose **Send out to be counted**.

From this point what was expected is fixed, so the count is measured against what was believed when
you ordered it — not against whatever happens in the meantime. A sheet with no lines cannot be sent
out.

### 3. Count

For each line, enter what you actually found in **Counted quantity**. That is the whole action: the
difference, whether it is out of tolerance, and who counted it and when are all filled in for you.

**Enter zero for a bin you found empty.** Zero is a count, and an empty bin is often the most important
thing a count finds. A line left blank is a line nobody has been to.

On a blind sheet you will not see **Expected quantity** or the difference while you are counting.

### 4. Mark it counted

When every line has a count, choose **Mark as counted**. If any line is still uncounted you are told
how many.

You can also choose **Mark fully counted sheets** on the sheet list to do this for every sheet that is
finished — nothing does it by itself.

### 5. Look at the differences, then close

Now the expected quantities and the differences are visible, whether or not the sheet was blind.

Lines marked **Out of tolerance** need a decision. Look at each one, and either:

- count it again — enter the new number in **Counted quantity**, which replaces the old one and takes
  any approval with it; or
- choose **Approve difference** to accept it.

Then choose **Close**. A sheet with a difference nobody has approved refuses to close and tells you how
many are waiting.

**Closing is what corrects the stock**, if you have set it to. Under **What was adjusted** the sheet
tells you what happened: **Posted** is ticked only when your stock has actually changed, **Posting
document no.** is the sheet's own number so you can find the entries, and each line shows the
**Posting quantity** it corrected by.

If something stops the correction being made — a blocked item, a closed period, a missing permission —
**the sheet does not close**. That is deliberate: a closed sheet that corrected nothing is exactly the
confusion this avoids. Fix what it complains about and close it again.

## Withdraw a sheet

Choose **Cancel**. Whatever was counted stays as a record.

A sheet nobody has counted anything on can be deleted, and its lines go with it. **Once anything on a
sheet has been counted it cannot be deleted** — not even after you cancel it. Cancel it and leave it,
so what was found survives.

## What counting does not do yet

- **It cannot correct a lot- or serial-tracked item counted by bin.** A correction to tracked goods
  has to name the lot, and counting by bin cannot know which one — bins hold several. Count tracked
  goods with the **Handling units** selection, which takes the lot from the pallet.
- **It does not choose what to count.** Nothing works out which aisle is due; you decide the slice and
  the sheet gathers it.
- **You cannot count on the handheld.** Counts are entered on the sheet.
- **There is no second-count round.** A difference is approved or recounted by hand; nothing asks for
  two independent counts and compares them.

## Load sample data

Sample sheets — one built from bins, one built from pallets and part-counted with a difference on it,
and one blind sheet nobody has started — can be loaded while turning the feature on. Switch on **Load
sample data** on the same step as **Enable this feature**. Load the handling unit sample data first if
you want the second sheet to have something on it.
