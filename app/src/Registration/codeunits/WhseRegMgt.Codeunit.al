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
    internal procedure LocationKeepsBins(LocationCode: Code[10]): Boolean
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
        if (MoveRequest."From Bin Code" = '') or (MoveRequest."To Bin Code" = '') then
            Error(BinMissingErr, MoveRequest."Item No.");
        if MoveRequest."From Bin Code" = MoveRequest."To Bin Code" then
            Error(SameBinErr, MoveRequest."Item No.", MoveRequest."From Bin Code");
    end;
}
