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

## What is not here yet

Nothing is sent or fetched over the network yet — the other system posts messages in and collects
them from the outbox itself. Stock corrections, counts and item information are not exchanged, and
there is no message for the other system to withdraw work it has already asked for. Messages are
kept indefinitely; there is no automatic clean-up.
