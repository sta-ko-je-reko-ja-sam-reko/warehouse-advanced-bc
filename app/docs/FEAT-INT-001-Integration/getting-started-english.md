# FEAT-INT-001 - Integration Surface

The integration surface is how this warehouse exchanges information with the system that feeds it
work. Everything that comes in and everything that goes out is kept as a **message**, so you can
always see what was received, what was done with it, and what is still waiting.

> The message formats are a first proposal, agreed while the real ones are unknown. Expect them to
> change once the other system's requirements are confirmed. Nothing you enter by hand is affected.

## Turn the integration surface on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Integration** row.
4. Read the introduction, then choose **Next**.
5. Switch on **Enable this feature**, then choose **Next** and **Finish**.
6. Close the feature list. Your session restarts so the change takes effect.

After the restart, **Integration messages** is available from the search.

## Choose how messages are handled

1. Choose the search icon, enter **Integration setup**, and choose the related link.
2. Fill in **Partner system** — a short code for the system you exchange with. It is written on
   every message so you can tell messages apart if you ever have more than one.
3. Switch **Process inbound messages on arrival** on if incoming messages should be acted on
   immediately. Leave it off if someone should look at them first, or if you prefer to run them on a
   schedule.
4. Switch **Release requested work** on if a job the other system asks for should go straight to the
   floor. Turn it off if someone here should check requested work first — the job is then created as
   a draft, and you release it yourself from **Warehouse tasks**.
5. Set **Max retry count** — how many times a message that failed is tried again automatically.
   Leave it at zero if failures should always be looked at by a person.

> A single message can ask for the opposite of your setting, and that wins for that message. So the
> other system can send most work to be checked and still push an urgent job straight through.

> If **Release tasks automatically** is switched on in the directed work setup, every task reaches
> the floor as it is created, whatever you choose here. Turn that off too if you want requested work
> held for review.

## What a message is

Every message has a **direction**:

- **Inbound** — it came from the other system. It is *processed*: acted on here.
- **Outbound** — this warehouse produced it. It waits in the outbox until the other system collects
  it, and is then *acknowledged*.

And a **status**:

- **New** — an inbound message waiting to be acted on, or an outbound one waiting to be collected.
- **Processed** — done.
- **Failed** — it could not be acted on. **Error message** says why.
- **Cancelled** — deliberately dropped without acting on it.

## What the other system can ask for, and what it is told

Twelve kinds of message exist. Six arrive here, six go back.

**What can arrive:**

| Message | What happens here |
|---|---|
| A pallet has been received | A handling unit appears, with its contents |
| A job is requested | One warehouse job is created |
| Release a warehouse receipt | Put-away work is raised for that receipt, exactly as if you had raised it yourself on the document |
| Release a warehouse shipment | Pick work is raised for that shipment, the same way |
| A stock correction | Stock is corrected, in the way you chose under **Adjustments** in the setup |
| Please count something | A count sheet is created for the location and filled in ready to count |

**What goes back:**

| Message | When it is produced |
|---|---|
| A job is finished | As each job completes, with anything that was short |
| A pallet has been despatched | As each handling unit ships |
| A warehouse receipt is finished | Once nothing on that receipt is still waiting to be put away |
| A warehouse shipment is finished | Once nothing on that shipment is still waiting to be picked |
| What a count found | When a count sheet is closed, not when it is counted |
| What is in stock | Once a day for each location, counting what is on handling units |

> **The three release and count messages carry no details.** They name the receipt, the shipment or
> the location and nothing else, so there is nothing in them to get wrong. If the same one arrives
> twice, the second is refused rather than doing the work again.

> **The stock statement counts what is on handling units**, not everything the company owns. If
> stock is standing somewhere this app was never told about, the statement and your inventory
> reports will differ — and finding that out is what the statement is for.

## Decide what a stock correction does

If the other system sends stock corrections, open **Integration setup** and fill in the
**Adjustments** section:

1. **Posting method** — choose whether a correction is only recorded, written to a journal for
   somebody here to check and post, or posted straight away. If you are unsure, choose the journal:
   nothing reaches your inventory until a person agrees to it.
2. If you chose the journal, fill in **Item journal template name** and **Item journal batch name**.
3. **Posting reason code** is optional, and worth setting — it is how you find these entries again.

## Work through the messages

1. Choose the search icon, enter **Integration messages**, and choose the related link.
2. The newest messages are at the top. Failed ones are highlighted.
3. Select a message and choose:
   - **Process** — act on an inbound message now.
   - **Acknowledge** — record that the other system has collected an outbound message.
   - **Cancel** — drop a message you do not want acted on. It stays in the list.
4. Choose **Process all waiting** to work through everything at once. Failed messages are tried
   again while they are within the retry count.
5. Choose **Fill the outbox** to prepare messages for everything the other system has not been told
   about yet — completed warehouse tasks and despatched handling units.

Open a message to see its full **payload** — exactly what was received or built. Choose **Show
record** to jump to the warehouse task or handling unit the message created or was built from.

## When a message fails

A failed message changed nothing. Whatever it started doing is undone, so you never have half a
pallet or a half-built job left over.

1. Open the message and read **Error message**. It is the same wording you would have seen on
   screen doing the same thing by hand.
2. Fix the cause — most often something the message refers to does not exist yet, such as a location
   or an item.
3. Choose **Process** again.

If the message is simply wrong and should never be acted on, choose **Cancel**.

> A message that is still waiting cannot be deleted. Cancel it instead. This is on purpose: the
> record of what arrived is the point of the list.

## Load sample data

If you want something to look at before the other system is connected, you can load a small set of
example messages: one waiting to be applied, one applied, one cancelled, one that failed with a real
error, and one waiting in the outbox.

You are offered this while turning the feature on — switch on **Load sample data** on the same step
as **Enable this feature**.

- The examples are created in the company you are working in.
- It is safe to run more than once. Nothing is duplicated.
- The examples use the locations and items your company already has.

## Run it on a schedule

An administrator can have the messages handled automatically:

1. Choose the search icon, enter **Job queue entries**, and choose the related link.
2. Create an entry that runs the codeunit named **WHA Int. Message Mgt.**
3. Choose how often it should run.

Each run acts on the inbound messages that are waiting and then fills the outbox.

## Stop the message log growing for ever

The message log is the one list in this app that nothing ever tidies. A partner sending a thousand
messages a day adds a thousand rows a day, each carrying the message itself, and no step in the
process removes one.

You clear it with Business Central's own **retention policies**, in the same place you set every other
one:

1. Choose the search icon, enter **Retention Policies**, and choose the related link.
2. Choose **New**, and pick the **Warehouse advanced integration message** table.
3. Set how long messages should be kept, and switch the policy on.

Three things are decided for you, and they are worth knowing:

- **Age is counted from when a message was processed**, not from when it arrived. A message sitting in
  the inbox unread is not getting old — nobody has dealt with it yet.
- **Only processed messages are covered by default.** A failed or cancelled message is the record of
  something going wrong, and it is not swept up unless you widen the filter yourself.
- **Nothing can be kept for less than a week.** This log is what an argument with the other system
  gets settled from.

**Until you create a policy, nothing is deleted.** This makes the clean-up possible, not automatic.

## What is not here yet

Nothing is sent or fetched over the network yet — the other system posts messages in and collects
them from the outbox itself. Item and unit-of-measure information is not exchanged and will not be:
the other system can read it from Business Central directly, because this app lives in the same
company. There is still no message for the other system to withdraw work it has already asked for.

A retention policy **deletes** old messages; nothing copies them anywhere first. If you have to keep a
year of interface traffic for audit, export it before the policy catches up with it — nothing will
remind you.
