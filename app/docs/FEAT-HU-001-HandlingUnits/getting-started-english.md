# FEAT-HU-001 - Handling Units

Handling units let you track a pallet, cage or carton as a single numbered thing. You can move it,
put it inside another unit, and label it for your customers.

## Turn handling units on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Handling units** row.
4. Read the introduction, then choose **Next**.
5. Switch on **Enable this feature**, then choose **Next** and **Finish**.
6. You return to the feature list, where **Handling units** now shows as **Completed**.
7. Close the feature list. Your session restarts so the change takes effect. This takes a few
   seconds and you do not need to sign in again.

After the restart, **Handling units** is available from the search.

> If you cannot find **Warehouse Advanced Setup**, ask your administrator — the app may not be
> assigned to you yet.

## Choose how nesting works

Nesting means putting one handling unit inside another, so that moving the outer one moves
everything inside it.

1. Choose the search icon, enter **Handling unit setup**, and choose the related link.
2. Set **Allow nesting** on or off.
3. If you allow nesting, set **Max nesting depth** to limit how many levels deep units may go.
   Leave it at zero for no limit.

## Load sample data

If you want something to look at before entering your own units, you can load a small set of
examples: a pallet, a carton inside that pallet, a closed cage, and a despatched pallet.

You are offered this while turning the feature on — switch on **Load sample data** on the same step
as **Enable this feature**.

- The examples are created in the company you are working in.
- It is safe to run more than once. Nothing is duplicated.
- The examples are for trying things out. Review them before relying on them in a company you use
  for real work.
- An administrator also gets a **configuration package** for handling units, which can be copied
  into other companies.

To remove an example later, open it and choose **Delete**. Take nested units out first.

## Create a handling unit

1. Choose the search icon, enter **Handling units**, and choose the related link.
2. Choose **New**.
3. The **No.** field fills in automatically.
4. Fill in **Description** so people can tell what the unit is.
5. Choose the **Location code** where the unit is, then the **Bin code** within it.
6. If your customers expect a labelled unit, fill in **SSCC**.
7. Close the page. The unit appears in the list.

> Changing the **Location code** clears the **Bin code**, because a bin belongs to one location.
> Choose the bin again after you change the location.

## Put one unit inside another

1. Open the handling unit you want to move inside another.
2. In **Parent handling unit**, choose the unit it should go into.
3. **Nested units** on the outer unit now counts this one.

To take a unit back out, clear **Parent handling unit**. That is always allowed.

You cannot put a unit inside itself, or inside one of its own nested units — the app will tell you
if you try. If nesting is switched off, or the unit would sit deeper than the maximum depth, you
will also be told.

## See what is inside a unit

1. Open the handling unit.
2. Choose **Nested units**.

The list shows the units placed directly inside it.

## Track where a unit is in its life

**Status** shows how far along a handling unit is:

- **Open** — still being built up; you can keep changing it.
- **Closed** — finished and ready to go.
- **Shipped** — it has left the warehouse.

## Delete a handling unit

Open the unit and choose **Delete**.

A unit that still holds nested units cannot be deleted. Take the inner units out first, then delete
the outer one.

## What is not here yet

A handling unit does not yet record **which goods and quantities it holds**. That is coming in the
next update, and it is what will let handling units be used in picking and shipping.
