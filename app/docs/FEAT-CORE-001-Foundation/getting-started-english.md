# FEAT-CORE-001 - Foundation

Setting the app up, switching features on and off, and the home page that shows you what needs doing.

## Set the app up

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link. You can
   also find it in **Assisted Setup**.
2. You get a list of everything the app can do. Each row tells you what the feature is for and whether
   it is switched on.
3. Choose a row, then **Set up**. A short wizard asks three things:
   - **Enable this feature** — whether you want it at all.
   - **Create and assign number series** — only offered for features that number something.
   - **Load sample data** — examples to try things out with.
4. Work down the list. Set up as few or as many as you like; the ones you skip stay hidden.
5. **Close the list when you are done.** Your session restarts once, so the features you switched on
   appear. It restarts once no matter how many features you set up.

**Detailed setup** on any row opens that feature's full settings, for the things the wizard does not
ask about.

## Turning a feature off later

Open its own setup page and clear **Enabled**, or come back to the list. Either way your session
restarts so the pages and actions disappear. **Nothing is deleted** — what the feature recorded stays,
and switching it back on brings it into view again.

## Your home page

A home page for the warehouse: what is waiting, what is stuck, and what nobody has looked at yet.

Everything else this app does happens on its own page — a job on the queue, a sheet on the floor, a
pallet on hold. This is the one page that answers the question you actually start the day with.

## Switch to it

1. Choose the settings icon, then **My Settings**.
2. Change **Role** to **Warehouse Advanced Manager**.
3. Choose **OK**. Your home page changes.

## What you get

A set of tiles, each a count of something that needs a person. Choose a tile to open the list behind
it.

| Tile | What it counts |
|---|---|
| **Jobs waiting** | Work released to the floor that nobody has picked up |
| **Jobs being done** | Work somebody has started and not finished |
| **Jobs past their date** | Unfinished work that was wanted before today |
| **Waves being built** / **Waves on the floor** | Batches still being put together, and batches out being worked |
| **Count sheets on the floor** | Counts sent out and still being counted |
| **Counts waiting for approval** | Counted sheets that cannot close until somebody accepts a difference |
| **Goods on hold** | Handling units stopped and unusable |
| **Holds waiting for a decision** | Held goods nobody has decided about — the ones that get forgotten |
| **Cartons being packed** | Cartons open at a bench right now |
| **Vehicles on site** / **Vehicles waiting for a door** | Vehicles arrived, and vehicles still waiting |
| **Messages waiting** / **Messages that failed** | Interface traffic you have not worked through, and traffic that did not work |
| **Replenishment rules switched off** | Rules that are blocked, and so are looking after no bin |
| **Slotting proposals waiting** | Proposed moves nobody has accepted or rejected |

**You only see tiles for the features you have switched on.** A warehouse that does not use waves has
no wave tiles — not tiles reading zero.

## The numbers arrive a moment after the page

The counts are worked out in the background, so the page opens straight away and the tiles fill in a
moment later. That is deliberate: a home page that waits for a dozen counts before it will show you
anything is a home page people stop opening.

If a count cannot be worked out, the page still opens and that tile stays at zero rather than showing
you an error on your home page.

## What is not here yet

There is almost no navigation on it — the guided setup and the foundation setup, and everything else
you reach by choosing a tile or by searching. There is no chart and no headline.

**No tile is ever red.** A tile tells you how many; nothing yet knows what a good number would be, so
nothing tells you whether you are winning.

There is one role, and it is the manager's. If you work on the floor, the handheld is what you want,
not this page.
