namespace WarehouseAdvanced.Registration;

using Microsoft.Inventory.Location;

codeunit 50802 "WHA Whse. Reg. Mgt."
{
    Access = Public;

    var
        ItemMissingErr: Label 'A warehouse move request line has no item on it, so there is nothing to register.';
        QuantityMissingErr: Label 'The warehouse move request for item %1 has no quantity on it, so there is nothing to register.', Comment = '%1 = the item number';
        LocationMissingErr: Label 'The warehouse move request for item %1 has no location on it, so there is no bin to register it against.', Comment = '%1 = the item number';
        BinMissingErr: Label 'The warehouse move request for item %1 does not say both where the goods came from and where they went, so it is not a move Business Central can record.', Comment = '%1 = the item number';
        SameBinErr: Label 'The warehouse move request for item %1 takes from bin %2 and puts back into bin %2, which is not a move.', Comment = '%1 = the item number; %2 = the bin code';
        IntoBinMissingErr: Label 'The warehouse request for item %1 does not say which bin the goods were added to.', Comment = '%1 = the item number';
        OutOfBinMissingErr: Label 'The warehouse request for item %1 does not say which bin the goods were taken out of.', Comment = '%1 = the item number';
        TwoEndedAdjustmentErr: Label 'The warehouse request for item %1 has a bin at both ends, which makes it a move rather than stock being added or taken away.', Comment = '%1 = the item number';

    /// <summary>
    /// Hands the request to the chosen way of recording a move. This is the single place a feature calls,
    /// so a feature never learns what any implementation does with what it is given.
    /// </summary>
    /// <param name="Method">The way of recording chosen in the calling feature's setup.</param>
    /// <param name="MoveRequest">The moves to record. Marked up in place with what happened to each.</param>
    /// <returns>How many moves the implementation recorded.</returns>
    internal procedure Register(Method: Enum "WHA Whse. Reg. Method"; var MoveRequest: Record "WHA Whse. Move Request"): Integer
    var
        WhseRegistration: Interface "WHA IWhseRegistration";
    begin
        WhseRegistration := Method;
        exit(WhseRegistration.Register(MoveRequest));
    end;

    /// <summary>
    /// Answers whether the chosen way of recording a move maintains bin content.
    /// </summary>
    /// <param name="Method">The way of recording chosen in the calling feature's setup.</param>
    /// <returns>True when a finished job changes what Business Central believes is in each bin.</returns>
    internal procedure UpdatesBinContent(Method: Enum "WHA Whse. Reg. Method"): Boolean
    var
        WhseRegistration: Interface "WHA IWhseRegistration";
    begin
        WhseRegistration := Method;
        exit(WhseRegistration.UpdatesBinContent());
    end;

    /// <summary>
    /// Describes in one line what the chosen way of recording a move does.
    /// </summary>
    /// <param name="Method">The way of recording chosen in the calling feature's setup.</param>
    /// <returns>A short description in the user's language.</returns>
    internal procedure Describe(Method: Enum "WHA Whse. Reg. Method"): Text
    var
        WhseRegistration: Interface "WHA IWhseRegistration";
    begin
        WhseRegistration := Method;
        exit(WhseRegistration.Describe());
    end;

    /// <summary>
    /// Registers stock being added to or taken out of a bin, as the other half of writing to the item
    /// ledger. This is deliberately **not** behind the method enum: where a feature has decided to post,
    /// telling the warehouse is not a second choice somebody could switch off — it is the rest of the
    /// same operation, and half of it is worse than neither half.
    /// </summary>
    /// <param name="MoveRequest">The changes to record. Marked up in place with what happened to each.</param>
    /// <returns>How many changes reached the warehouse entries.</returns>
    internal procedure RegisterAdjustment(var MoveRequest: Record "WHA Whse. Move Request"): Integer
    var
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        exit(WhseJnlRegistration.Register(MoveRequest));
    end;

    /// <summary>
    /// Answers the next free entry number on a request buffer, so a caller building one does not have to
    /// count its own lines. It reads the buffer, so it **repositions the record** — ask for the number
    /// before calling Init, not after, or the fields just initialised are overwritten.
    /// </summary>
    /// <param name="MoveRequest">The request buffer being built. Reset and repositioned by this call.</param>
    /// <returns>One more than the highest entry number on the buffer.</returns>
    internal procedure NextEntryNo(var MoveRequest: Record "WHA Whse. Move Request"): Integer
    begin
        MoveRequest.Reset();
        if not MoveRequest.FindLast() then
            exit(1);
        exit(MoveRequest."Entry No." + 1);
    end;

    /// <summary>
    /// Answers whether Business Central keeps bins at a location. Where it does not, there is no
    /// bin-level record to keep true, and a move the app makes is complete once the app has made it.
    /// </summary>
    /// <param name="LocationCode">The location to ask about. Blank counts as keeping no bins.</param>
    /// <returns>True when the location is bin mandatory.</returns>
    procedure LocationKeepsBins(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);
        Location.SetLoadFields("Bin Mandatory");
        if not Location.Get(LocationCode) then
            exit(false);
        exit(Location."Bin Mandatory");
    end;

    /// <summary>
    /// Answers whether a location runs directed put-away and pick. It is a public question because the
    /// answer changes what any caller may do: at such a location bins live in warehouse entries alone,
    /// an item journal line carries no bin at all, and the two halves have to be written separately.
    /// </summary>
    /// <param name="LocationCode">The location to ask about. Blank counts as not directed.</param>
    /// <returns>True when the location runs directed put-away and pick.</returns>
    procedure LocationIsDirected(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);
        Location.SetLoadFields("Directed Put-away and Pick");
        if not Location.Get(LocationCode) then
            exit(false);
        exit(Location."Directed Put-away and Pick");
    end;

    /// <summary>
    /// Answers whether Business Central raises warehouse activities of its own at a location — its own
    /// put-away and pick documents, with their own lines and their own registering.
    /// </summary>
    /// <remarks>
    /// Where it does, this app must not also raise work for the same goods: neither queue can see the
    /// other, and an operator would be sent to the same bin twice. A location with directed put-away and
    /// pick always answers true, because Business Central turns all four *Require* flags on with it and
    /// will not let them be turned back off.
    /// </remarks>
    /// <param name="LocationCode">The location to ask about. Blank counts as raising nothing.</param>
    /// <returns>True when the location requires Business Central's own put-away or pick.</returns>
    procedure LocationRaisesOwnActivities(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);
        Location.SetLoadFields("Require Put-away", "Require Pick");
        if not Location.Get(LocationCode) then
            exit(false);
        exit(Location."Require Put-away" or Location."Require Pick");
    end;

    /// <summary>
    /// Refuses a request line that is not a move. Every implementation that records anything calls this
    /// first, so a caller that builds a half-filled line hears about it here rather than three layers
    /// down inside Business Central.
    /// </summary>
    /// <param name="MoveRequest">The request line to check.</param>
    internal procedure CheckRequestLine(var MoveRequest: Record "WHA Whse. Move Request")
    begin
        if MoveRequest."Item No." = '' then
            Error(ItemMissingErr);
        if MoveRequest.Quantity <= 0 then
            Error(QuantityMissingErr, MoveRequest."Item No.");
        if MoveRequest."Location Code" = '' then
            Error(LocationMissingErr, MoveRequest."Item No.");

        case MoveRequest."Change Type" of
            MoveRequest."Change Type"::WHAMove:
                begin
                    if (MoveRequest."From Bin Code" = '') or (MoveRequest."To Bin Code" = '') then
                        Error(BinMissingErr, MoveRequest."Item No.");
                    if MoveRequest."From Bin Code" = MoveRequest."To Bin Code" then
                        Error(SameBinErr, MoveRequest."Item No.", MoveRequest."From Bin Code");
                end;
            MoveRequest."Change Type"::WHAIncrease:
                begin
                    if MoveRequest."To Bin Code" = '' then
                        Error(IntoBinMissingErr, MoveRequest."Item No.");
                    if MoveRequest."From Bin Code" <> '' then
                        Error(TwoEndedAdjustmentErr, MoveRequest."Item No.");
                end;
            MoveRequest."Change Type"::WHADecrease:
                begin
                    if MoveRequest."From Bin Code" = '' then
                        Error(OutOfBinMissingErr, MoveRequest."Item No.");
                    if MoveRequest."To Bin Code" <> '' then
                        Error(TwoEndedAdjustmentErr, MoveRequest."Item No.");
                end;
        end;
    end;
}
