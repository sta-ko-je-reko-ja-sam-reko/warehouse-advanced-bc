# FEAT-DOCK-001 - Dock and yard

Business Central knows a delivery arrived. It does not know which door it came through, what time the
lorry reported at the gate, where the trailer is standing now, or how long the driver waited.

This is where you write that down: the doors you have, the places a trailer can wait, and a booking
for every vehicle coming to see you.

## Turn dock and yard on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. Work through the **Foundation** step first if you have not already. It creates the numbering that
   bookings use.
4. Choose the **Dock and yard** row, then **Next**.
5. Switch on **Enable this feature**, then **Next** and **Finish**.
6. Close the feature list. Your session restarts so the change takes effect.

Nothing else has to be switched on. This feature does not need handling units, warehouse jobs or
anything else — it stands on its own.

## Decide how the yard runs

1. Choose the search icon, enter **Dock and yard setup**, and choose the related link.
2. **Choose a door by** — how a door is picked when whoever takes the booking does not name one, with
   **What that means** underneath spelling it out:
   - **The first free door** — always works down the list in the same order. Choose this when your
     doors are not equivalent, because drivers learn one route.
   - **The least busy door** — spreads the day across the building. Choose this when the doors are
     interchangeable and the limit is how many people you have.
   Either way, a door that is blocked, points the wrong way, or is already promised to somebody else
   is never chosen.
3. **How long a slot lasts** — how much of the door a booking takes when nobody says otherwise. This
   is what stops two lorries being promised the same door at the same time.
4. **Late after this many minutes** — how late a vehicle has to be before you want to see it
   highlighted. It changes what is coloured, never what is allowed.
5. **A waiting vehicle needs a yard position** — switch this on for a yard big enough that "it is out
   there somewhere" stops being an answer. Then nobody can check a vehicle in without saying where
   the trailer went.

## Write down your doors

1. Choose the search icon, enter **Dock doors**, and choose the related link.
2. Add one line per door: the location, the code painted above it, what it is, and whether it takes
   goods **in**, **out**, or both.
3. **Waiting position** is where vehicles for that door normally wait. It is offered automatically at
   check-in, so filling it in saves typing later.

Block a door while it is out of use. Nothing new is booked onto a blocked door, and anything already
standing at it is left alone.

## Write down where trailers can stand

Choose the search icon, enter **Yard positions**, and choose the related link. Add one line per
parking place, using the number painted on the ground — somebody has to find the trailer again.

The **Occupied by** column always shows what is standing there **now**. It clears itself when the
vehicle moves to a door or leaves.

## Book a vehicle in

Choose the search icon, enter **Dock appointments**, and choose the related link.

For each booking, fill in the location, whether the vehicle is coming in or going out, when it is
expected, who is coming, the trailer, and what it is here for.

- **Leave the door blank** and one is chosen for you.
- **Fill the door in** and it is checked: the wrong direction, a blocked door, or a door already
  promised at that time is refused, and the message names the booking that already has it.
- If nothing is free at that time, the booking is still taken **without a door**. You have already
  made the promise; the app is not going to pretend you did not. Choose **Choose a door** later to
  give it one.

A booking whose vehicle has not turned up by the time you set shows in red.

## The day itself

Use the three actions on the appointment, in order:

1. **Check in** when the vehicle reports at the gate. The trailer is parked in the waiting position
   its door suggests. To park it somewhere else, open the booking and fill in **Park in** first.
2. **To the door** when you bring it in. The yard position is given back automatically, and you
   cannot put a second vehicle on a door that already has one at it.
3. **Depart** when it leaves.

Each of those three writes down the time it happened. Those times are the whole point: they are what
the warehouse KPIs read to tell you how long drivers wait and how long a visit really takes.

## When a vehicle does not come

Choose **Call it off**. The booking is kept, marked as called off, and the door and yard position go
back into the pool.

**A vehicle that has been on site cannot be deleted.** When it came and when it left is the only
record of what your yard did that day, and it is the only thing a haulier's invoice can be checked
against.

## What dock and yard does not do yet

- **It does not know what was on the lorry.** A booking has a reference you type; it is not linked to
  a purchase order, a receipt or a shipment.
- **It does not know how busy you are.** A slot is a door and a length of time, not people, forklifts
  or how long the load will really take.
- **It has no opening hours.** Nothing stops a booking at three in the morning on a Sunday.
- **Carriers cannot book themselves in.** Bookings are made by your own people.
- **There is no gate screen on the handheld.** Check-in is done in the office.
- **Trailers have no history.** The trailer number is text, so the app cannot tell you when that unit
  was last here.

## Load sample data

Switching **Load sample data** on in the guided setup adds three doors, two yard positions and two
bookings at your first location, one of them taken all the way through arrival, the door and
departure so there is a finished visit to look at. Running it again does not create duplicates.
