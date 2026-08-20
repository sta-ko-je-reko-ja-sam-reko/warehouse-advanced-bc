namespace WarehouseAdvanced.DirectedWork;

codeunit 50210 "WHA Allow Open Work" implements "WHA IOpenWorkPolicy"
{
    Access = Public;

    var
        DescriptionLbl: Label 'Nothing is held. A receipt or shipment can be posted while jobs raised from it are still on the floor, and whoever posts it is not told.';

    /// <summary>
    /// Lets the document through. This is what the app did before it could see a posting at all, kept as
    /// a choice rather than a missing feature: a warehouse that posts the document first and finishes the
    /// work afterwards is describing a real way of working, not a mistake.
    /// </summary>
    /// <param name="SourceType">The kind of document being posted. Ignored.</param>
    /// <param name="SourceNo">The document being posted. Ignored.</param>
    procedure Check(SourceType: Enum "WHA Task Source"; SourceNo: Code[20])
    begin
    end;

    /// <summary>
    /// Describes in one line what this policy does.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;
}
