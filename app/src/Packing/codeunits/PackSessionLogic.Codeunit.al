namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.HandlingUnit;

codeunit 50400 "WHA Pack Session Logic" implements "WHA IPackSession"
{
    Access = Public;

    var
        StationRequiredErr: Label 'Choose a packing station before you start. The station is what decides where the carton is.';
        UnknownStationErr: Label 'There is no packing station called %1.', Comment = '%1 = the station code that was entered';
        StationBlockedErr: Label 'Packing station %1 is out of use.', Comment = '%1 = the station code';
        NotPackingErr: Label 'Packing session %1 is %2, so nothing more can go into the carton.', Comment = '%1 = the session entry number, %2 = the current status';
        EmptyCartonErr: Label 'The carton in packing session %1 is empty. Closing an empty carton would tell everybody downstream that something was packed.', Comment = '%1 = the session entry number';
        NotVerifiedErr: Label 'The carton in packing session %1 has not been checked, and the packing setup asks for a check before a carton is closed.', Comment = '%1 = the session entry number';
        AlreadyClosedErr: Label 'Packing session %1 is already %2.', Comment = '%1 = the session entry number, %2 = the current status';
        DeleteNotAllowedErr: Label 'Packing session %1 cannot be deleted while its status is %2. It produced a carton that may already have left. Cancel it instead.', Comment = '%1 = the session entry number, %2 = the current status';
        NothingToPackErr: Label 'Say what is going into the carton, and how much.', Comment = 'Shown when the item or the quantity is missing';
        CartonDescriptionLbl: Label 'Packed at %1', Comment = '%1 = the packing station code';

    /// <summary>
    /// Stamps a new packing session with who started it and when.
    /// </summary>
    /// <param name="PackSession">The session being inserted.</param>
    procedure Trigger_OnInsert(var PackSession: Record "WHA Pack Session")
    begin
        if PackSession."Started At" = 0DT then
            PackSession."Started At" := CurrentDateTime;
        if PackSession."Packed By User ID" = '' then
            PackSession."Packed By User ID" := CopyStr(UserId(), 1, MaxStrLen(PackSession."Packed By User ID"));
    end;

    /// <summary>
    /// Refuses to delete a session that produced a carton somebody may have taped shut and shipped.
    /// </summary>
    /// <param name="PackSession">The session being deleted.</param>
    procedure Trigger_OnDelete(var PackSession: Record "WHA Pack Session")
    begin
        if PackSession.Status in [PackSession.Status::WHAClosed, PackSession.Status::WHAVerified] then
            Error(DeleteNotAllowedErr, PackSession."Entry No.", PackSession.Status);
    end;

    /// <summary>
    /// Opens a carton at a bench and starts packing into it. The carton is a handling unit, so
    /// everything the rest of the app knows about handling units applies to it from the first moment.
    /// </summary>
    /// <param name="PackSession">Receives the new session.</param>
    /// <param name="StationCode">The bench being worked at.</param>
    procedure Start(var PackSession: Record "WHA Pack Session"; StationCode: Code[20])
    var
        PackStation: Record "WHA Pack Station";
        HandlingUnit: Record "WHA Handling Unit";
    begin
        if StationCode = '' then
            Error(StationRequiredErr);
        if not PackStation.Get(StationCode) then
            Error(UnknownStationErr, StationCode);
        if PackStation.Blocked then
            Error(StationBlockedErr, StationCode);

        CreateCarton(HandlingUnit, PackStation);

        PackSession.Init();
        PackSession."Station Code" := PackStation.Code;
        PackSession."Handling Unit No." := HandlingUnit."No.";
        PackSession.Status := PackSession.Status::WHAPacking;
        PackSession.Insert(true);
    end;

    /// <summary>
    /// Puts goods into the carton being packed.
    /// </summary>
    /// <param name="PackSession">The session being worked.</param>
    /// <param name="ItemNo">What is going in.</param>
    /// <param name="VariantCode">Which variant, if any.</param>
    /// <param name="Quantity">How much.</param>
    procedure PackItem(var PackSession: Record "WHA Pack Session"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        CheckPacking(PackSession);

        if (ItemNo = '') or (Quantity <= 0) then
            Error(NothingToPackErr);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := PackSession."Handling Unit No.";
        HandlingUnitLine.Validate("Item No.", ItemNo);
        if VariantCode <> '' then
            HandlingUnitLine.Validate("Variant Code", VariantCode);
        HandlingUnitLine.Validate(Quantity, Quantity);
        HandlingUnitLine.Insert(true);
    end;

    /// <summary>
    /// Records that somebody has checked what is in the carton against what should be.
    /// </summary>
    /// <param name="PackSession">The session being verified.</param>
    procedure Verify(var PackSession: Record "WHA Pack Session")
    begin
        CheckPacking(PackSession);

        if IsEmptyCarton(PackSession) then
            Error(EmptyCartonErr, PackSession."Entry No.");

        PackSession."Verified By User ID" := CopyStr(UserId(), 1, MaxStrLen(PackSession."Verified By User ID"));
        PackSession.Status := PackSession.Status::WHAVerified;
        PackSession.Modify(true);
    end;

    /// <summary>
    /// Closes the carton. Refuses an empty one, and refuses an unverified one when the setup asks for
    /// verification.
    /// </summary>
    /// <param name="PackSession">The session to close.</param>
    procedure Close(var PackSession: Record "WHA Pack Session")
    var
        Setup: Record "WHA Pack Setup";
    begin
        if PackSession.Status in [PackSession.Status::WHAClosed, PackSession.Status::WHACancelled] then
            Error(AlreadyClosedErr, PackSession."Entry No.", PackSession.Status);
        if IsEmptyCarton(PackSession) then
            Error(EmptyCartonErr, PackSession."Entry No.");

        Setup.SetLoadFields("Require Verification", "Close Unit When Closed");
        if Setup.Get() then
            if Setup."Require Verification" and (PackSession.Status <> PackSession.Status::WHAVerified) then
                Error(NotVerifiedErr, PackSession."Entry No.");

        PackSession.Status := PackSession.Status::WHAClosed;
        PackSession."Closed At" := CurrentDateTime;
        PackSession.Modify(true);

        if Setup."Close Unit When Closed" then
            CloseCarton(PackSession);
    end;

    /// <summary>
    /// Abandons the packing. The carton stays as it is, holding whatever was already put in it.
    /// </summary>
    /// <param name="PackSession">The session to cancel.</param>
    procedure Cancel(var PackSession: Record "WHA Pack Session")
    begin
        if PackSession.Status in [PackSession.Status::WHAClosed, PackSession.Status::WHACancelled] then
            Error(AlreadyClosedErr, PackSession."Entry No.", PackSession.Status);

        PackSession.Status := PackSession.Status::WHACancelled;
        PackSession.Modify(true);
    end;

    local procedure CreateCarton(var HandlingUnit: Record "WHA Handling Unit"; var PackStation: Record "WHA Pack Station")
    begin
        HandlingUnit.Init();
        HandlingUnit.Validate(Description, CopyStr(StrSubstNo(CartonDescriptionLbl, PackStation.Code), 1, MaxStrLen(HandlingUnit.Description)));
        if PackStation."Location Code" <> '' then
            HandlingUnit.Validate("Location Code", PackStation."Location Code");
        if PackStation."Bin Code" <> '' then
            HandlingUnit.Validate("Bin Code", PackStation."Bin Code");
        HandlingUnit.Insert(true);
    end;

    local procedure CloseCarton(var PackSession: Record "WHA Pack Session")
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        if not HandlingUnit.Get(PackSession."Handling Unit No.") then
            exit;
        if HandlingUnit.Status <> HandlingUnit.Status::WHAOpen then
            exit;

        HandlingUnit.Validate(Status, HandlingUnit.Status::WHAClosed);
        HandlingUnit.Modify(true);
    end;

    local procedure IsEmptyCarton(var PackSession: Record "WHA Pack Session"): Boolean
    var
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        HandlingUnitLine.SetLoadFields("Handling Unit No.");
        HandlingUnitLine.SetRange("Handling Unit No.", PackSession."Handling Unit No.");
        exit(HandlingUnitLine.IsEmpty());
    end;

    local procedure CheckPacking(var PackSession: Record "WHA Pack Session")
    begin
        if PackSession.Status <> PackSession.Status::WHAPacking then
            Error(NotPackingErr, PackSession."Entry No.", PackSession.Status);
    end;
}
