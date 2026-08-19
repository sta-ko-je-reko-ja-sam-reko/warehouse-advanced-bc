# FEAT-PACK-001 - Packing

Packing is the bench where loose goods go into a carton. You open a carton, put things in, check
what went in, and close it. The closed carton is then a handling unit like any other — it can be
labelled, moved, put on a pallet and shipped.

## Turn packing on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Packing** row, then **Next**.
4. Switch on **Enable this feature**, then **Next** and **Finish**.
5. Close the feature list. Your session restarts so the change takes effect.

Handling units must be on as well, with its numbering created — a carton is a handling unit and needs
a number, and that series belongs to the handling unit feature.

## Set up your benches

1. Choose the search icon, enter **Packing stations**, and choose the related link.
2. Choose **New**.
3. Fill in **Code** and **Description** so packers know which bench is which.
4. Choose the **Location code** the bench stands in, and the **Bin code** cartons packed there
   should be put in — usually the bench itself or the staging area beside it. **Cartons are created
   where the bench is**, so this is worth getting right.
5. Switch on **Blocked** for a bench that is out of use. Nobody can pack there.

Then set the defaults:

1. Choose the search icon, enter **Packing setup**, and choose the related link.
2. Choose a **Default station** — the bench offered first when somebody opens the packing screen.
3. Leave **Require verification** on unless you have decided speed matters more than a second pair
   of eyes. With it off, cartons can be closed without anybody confirming what is in them.
4. Leave **Close the handling unit too** on. The carton has been taped shut, so nothing more should
   be able to go into it.

## Pack a carton

1. Choose the search icon, enter **Packing station**, and choose the related link.
2. Check the **Station** is the bench you are at.
3. Choose **New carton**. A carton is opened and numbered for you.
4. For each kind of goods going in:
   - Fill in **Item no.**, the **Variant code** if there is one, and the **Quantity**.
   - Choose **Put in**.
   **What is in the carton** below shows everything you have added.
5. Choose **Check** when you have been through the carton. This records that *you* checked it.
6. Choose **Close carton**.

The carton is now sealed. Nothing more can be put into it, and it appears in **Handling units** like
any other.

> An empty carton cannot be checked or closed. Closing an empty one would tell everybody downstream
> that something had been packed.

## If you have to walk away

Choose **Abandon**.

Whatever you had already put in the carton **stays in it**. The box on the bench and the system
still agree — which is the point. Somebody can pick it up later and deal with it.

## What "check" means here

Choosing **Check** records that you say you looked. It does **not** compare the carton against an
order or a picking list, because the app does not yet know what this carton was supposed to contain.

So it is a signature, not a proof. Treat it that way, and do not let it stand in for actually
looking.

## Load sample data

Sample benches and one worked example carton can be loaded while turning the feature on — switch on
**Load sample data** on the same step as **Enable this feature**.

- Three benches are created, one of them blocked.
- One carton is packed, checked and closed, so the list is not empty.
- It is safe to run more than once, and it does not pack a second carton.

## What is not here yet

Nothing tells you which size box to use. Nothing prints a packing list. And a carton is not yet
packed *for* anything — there is no link to an order or a shipment, so nothing checks that you
packed the right things. Those come with later work.
