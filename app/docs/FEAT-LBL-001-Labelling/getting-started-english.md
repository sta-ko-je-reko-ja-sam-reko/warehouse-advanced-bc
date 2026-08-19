# FEAT-LBL-001 - Labelling

Labelling gives a handling unit the code that goes on its label — either an **SSCC**, the 18-digit
code your trading partners can scan, or a plain **licence plate** for use inside your own warehouse.

## Turn labelling on

You only need to do this once, and you need administrator rights.

1. Choose the search icon, enter **Warehouse Advanced Setup**, and choose the related link.
2. Choose **Guided setup**.
3. In the list of features, choose the **Labelling** row, then **Next**.
4. Switch on **Enable this feature**, then **Next** and **Finish**.
5. Close the feature list. Your session restarts so the change takes effect.

Handling units must be on as well — the code goes on a handling unit.

## Set up your codes

1. Choose the search icon, enter **Labelling setup**, and choose the related link.
2. Choose the **Format**:
   - **SSCC (GS1)** if your customers or carriers expect a standard code they can scan.
   - **Sequential licence plate** if the numbers only ever need to mean something inside your own
     building.
   **What the code looks like** tells you what you will get.
3. Fill in **GS1 company prefix**. For SSCC this must be **exactly the digits GS1 issued to you** —
   there is no default, because a made-up prefix produces codes that look valid and identify
   somebody else. For a licence plate it is just a few letters of your choosing.
4. Set the **Extension digit** if your codes should start with something meaningful, such as a digit
   that says how big the unit is. Leave it at zero if it means nothing to you.
5. Choose **Show an example code** to see what the next code will look like. This does **not** use
   the code up — you can check as often as you like.

> **Last serial reference** counts the codes you have given out. It only ever goes up, and you
> cannot type over it. A number that came round again would mean two pallets wearing the same label.

## Give a unit its code

1. Choose the search icon, enter **Handling units**, and choose the related link.
2. Open the unit.
3. Choose **Assign label code**.

The code appears in **SSCC** on the unit, and that is the code to print.

> **A unit is only labelled once.** If it already has a code you are told so, and the old one is
> kept. This is deliberate: the label is printed and stuck on, and if the sticker and the system
> disagree, people believe the sticker.

> A unit that has already shipped cannot be labelled. There would be nothing to stick it to.

## Checking a code that came from somewhere else

An SSCC has a check digit — the last one — which is calculated from all the others. That is what
lets a scanner tell a misread from a real code, and it is why a code you type by hand may be
refused: one wrong digit and the sum no longer works out.

If a partner sends you a code that will not go in, the usual cause is a transcription error rather
than a disagreement about the code.

## Load sample data

Sample labels can be loaded while turning the feature on — switch on **Load sample data** on the
same step as **Enable this feature**. It sets an example GS1 prefix and labels the sample handling
units that have no code yet.

- Load the handling unit sample data first, or there is nothing to label.
- It is safe to run more than once. Units that already have a code keep the code they have.
- **The example prefix is not yours.** Replace it with the prefix GS1 issued to you before you print
  anything a customer will see.

## What is not here yet

Nothing prints. This feature works out the code that belongs on the label; producing the label
itself — the layout, the barcode image, and sending it to the right printer — is not built. Codes
are given out one unit at a time, by hand or by another system; nothing assigns them automatically
when a unit is created.
