namespace WarehouseAdvanced.QualityHold;

using WarehouseAdvanced.HandlingUnit;

codeunit 50555 "WHA Disp. Pending" implements "WHA IHoldDisposition"
{
    Access = Public;

    var
        NotDecidedErr: Label 'Nobody has decided what happens to the goods on hold %1, so it cannot be released. Choose a disposition first.', Comment = '%1 = the hold entry number';
        DescriptionLbl: Label 'Nothing has been decided yet. The goods stay where they are.';

    /// <summary>
    /// Refuses the release. A hold lifted without a decision is a hold that achieved nothing, and the
    /// goods go back into stock by default — which is the outcome quality hold exists to prevent.
    /// </summary>
    /// <param name="QualityHold">The hold being released.</param>
    /// <param name="HandlingUnit">The handling unit the hold was placed on.</param>
    procedure Apply(var QualityHold: Record "WHA Quality Hold"; var HandlingUnit: Record "WHA Handling Unit")
    begin
        Error(NotDecidedErr, QualityHold."Entry No.");
    end;

    /// <summary>
    /// Describes in one line what this decision does to the goods.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this decision puts the goods back into use.
    /// </summary>
    /// <returns>False. Nothing has been decided.</returns>
    procedure ReturnsToUse(): Boolean
    begin
        exit(false);
    end;
}
