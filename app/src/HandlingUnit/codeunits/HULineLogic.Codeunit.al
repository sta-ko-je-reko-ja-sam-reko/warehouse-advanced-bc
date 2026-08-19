namespace WarehouseAdvanced.HandlingUnit;

using Microsoft.Inventory.Item;

codeunit 50054 "WHA HU Line Logic" implements "WHA IHandlingUnitLine"
{
    Access = Public;

    var
        UnitNotOpenErr: Label 'Goods cannot be added to handling unit %1 because its status is %2. Only an open handling unit can be changed.', Comment = '%1 = the handling unit number, %2 = the current status';
        NegativeQuantityErr: Label 'The quantity on a handling unit line cannot be negative.';
        SerialQuantityErr: Label 'A line with a serial number must have a quantity of one, because a serial number identifies a single item.';

    /// <summary>
    /// Assigns the next line number and refuses the insert when the handling unit is no longer open.
    /// </summary>
    /// <param name="HandlingUnitLine">The line being inserted.</param>
    procedure Trigger_OnInsert(var HandlingUnitLine: Record "WHA Handling Unit Line")
    var
        HandlingUnit: Record "WHA Handling Unit";
    begin
        HandlingUnit.SetLoadFields(Status);
        if HandlingUnit.Get(HandlingUnitLine."Handling Unit No.") then
            if HandlingUnit.Status <> HandlingUnit.Status::WHAOpen then
                Error(UnitNotOpenErr, HandlingUnit."No.", HandlingUnit.Status);

        if HandlingUnitLine."Line No." = 0 then
            HandlingUnitLine."Line No." := GetNextLineNo(HandlingUnitLine."Handling Unit No.");
    end;

    /// <summary>
    /// Copies the description and base unit of measure from the item, and clears the variant when the
    /// item changes so a variant of the previous item cannot be kept.
    /// </summary>
    /// <param name="HandlingUnitLine">The line being validated.</param>
    /// <param name="xHandlingUnitLine">The line as it was before the change.</param>
    procedure Validate_ItemNo(var HandlingUnitLine: Record "WHA Handling Unit Line"; xHandlingUnitLine: Record "WHA Handling Unit Line")
    var
        Item: Record Item;
    begin
        if HandlingUnitLine."Item No." = xHandlingUnitLine."Item No." then
            exit;

        HandlingUnitLine."Variant Code" := '';
        HandlingUnitLine.Description := '';
        HandlingUnitLine."Unit of Measure Code" := '';

        if HandlingUnitLine."Item No." = '' then
            exit;

        Item.SetLoadFields(Description, "Base Unit of Measure");
        if not Item.Get(HandlingUnitLine."Item No.") then
            exit;

        HandlingUnitLine.Description := Item.Description;
        HandlingUnitLine."Unit of Measure Code" := Item."Base Unit of Measure";
    end;

    /// <summary>
    /// Rejects a negative quantity, and rejects a quantity other than one when the line carries a
    /// serial number.
    /// </summary>
    /// <param name="HandlingUnitLine">The line being validated.</param>
    /// <param name="xHandlingUnitLine">The line as it was before the change.</param>
    procedure Validate_Quantity(var HandlingUnitLine: Record "WHA Handling Unit Line"; xHandlingUnitLine: Record "WHA Handling Unit Line")
    begin
        if HandlingUnitLine.Quantity < 0 then
            Error(NegativeQuantityErr);

        if (HandlingUnitLine."Serial No." <> '') and (HandlingUnitLine.Quantity <> 1) then
            Error(SerialQuantityErr);
    end;

    /// <summary>
    /// Returns the next free line number for a handling unit.
    /// </summary>
    /// <param name="HandlingUnitNo">The handling unit to number a line for.</param>
    /// <returns>The next line number, in steps of ten thousand.</returns>
    procedure GetNextLineNo(HandlingUnitNo: Code[20]): Integer
    var
        ExistingLine: Record "WHA Handling Unit Line";
    begin
        ExistingLine.SetLoadFields("Line No.");
        ExistingLine.SetRange("Handling Unit No.", HandlingUnitNo);
        if ExistingLine.FindLast() then
            exit(ExistingLine."Line No." + LineNoStep());

        exit(LineNoStep());
    end;

    local procedure LineNoStep(): Integer
    begin
        exit(10000);
    end;
}
