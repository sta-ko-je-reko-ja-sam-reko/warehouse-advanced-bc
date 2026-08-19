# FEAT-RF-001 - Mobile Device

The handheld screen is the warehouse floor's version of this app. An operator signs in on a scanner,
asks for their next job, and scans their way through it. One instruction at a time, no typing.

> This screen is a first version. It has not yet been tried by operators on the floor, and the order
> of the steps is expected to change once it has. Tell whoever set it up what gets in your way.

## Turn the handheld on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Handheld** row.
4. Read the introduction, then choose **Next**.
5. Switch on **Enable this feature**, then choose **Next** and **Finish**.
6. Close the feature list. Your session restarts so the change takes effect.

Directed work must be switched on as well — the handheld is a way of working the job queue, so
without it there is nothing to hand out.

## Choose how the handheld behaves

1. Choose the search icon, enter **Handheld setup**, and choose the related link.
2. **Confirm by scan** — leave this on. The operator has to scan the bin and the pallet to prove they
   are in the right place. Switch it off only for demonstrations: with it off, a job is one tap and
   proves nothing.
3. **Start work automatically** — leave this on. On a handheld there is no gap between being given a
   job and starting it.
4. **Require device registration** — on means only handhelds registered here can be used. Turn it
   off while you are trying the screen out from a desktop.
5. **Flow** — the order of the steps. Leave it at **Standard** unless someone has added another.

## Register your handhelds

1. Choose the search icon, enter **Handheld devices**, and choose the related link.
2. Choose **New**.
3. Fill in **Code** — put the same code on a label stuck to the device, so the operator can scan it.
4. Fill in **Description** so you can tell which device it is.
5. Set **Default location code** to the part of the warehouse the device lives in. An operator
   signed in on it is only offered work there. Leave it blank to offer work anywhere.
6. Switch on **Blocked** for a device that is broken or lost. Nobody can sign in on it.

**Last user ID** and **Last seen at** fill in by themselves each time somebody signs in — useful for
finding a device that has gone quiet.

## Working on the handheld

1. Choose the search icon, enter **Handheld**, and choose the related link.
2. **Scan the code on the device.** You are signed in, and the screen tells you which location you
   are working in.
3. Choose **Next task**. If there is work waiting you are given the most urgent job at your location;
   if you already had a job in your hands, you get that one back first.
4. Follow the line at the top of the screen. It says one thing at a time:
   - *Go to bin B-01-0001 and scan it.*
   - *Scan handling unit HU000042.* — scan either the number or the barcode on its label; both work.
   - *Put it in bin STAGE-01 and scan it.*
5. Choose **Confirm** to finish. The job is done, the pallet is recorded in its new bin, and you are
   ready for the next one.

**Your job** on the screen shows what you are carrying, where it came from and where it goes.

## When a scan is refused

The screen tells you what you scanned and where you should be instead — for example *"You scanned
B-02-0007. Go to bin B-01-0001."*

That is the screen doing its job. Go to the bin it names and scan again. If the bin or pallet it
asks for does not exist where it says, hand the job back and tell your supervisor: something is
wrong with the job, not with you.

## When you cannot finish a job

Choose **Hand back**. The job returns to the queue and anybody, including you, can be given it
again. Nothing is lost, and it is not recorded against you as started.

Do this rather than walking away with a job in your hands: a job nobody has handed back stays with
you, and nobody else will be offered it.

## Load sample data

Sample handhelds — one tied to a location, one that works anywhere, and one blocked — can be loaded
while turning the feature on. Switch on **Load sample data** on the same step as **Enable this
feature**. It is safe to run more than once.

## What is not here yet

You cannot yet say that only part of a job was possible — that there were four on the shelf and not
twelve. There is no way to scan the item or the lot, only the pallet. And the screen needs a
connection: if it drops, you lose your place on the job, though not the job itself.
