namespace WarehouseAdvanced.Core;

table 50003 "WHA Activities Cue"
{
    Caption = 'Warehouse advanced activities';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary key';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the single row the activity tiles are bound to.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Makes sure the one in-memory row the tiles bind to exists. There is no persisted table behind
    /// this: the counts are worked out in the background every time the role centre opens, because a
    /// number that is stored is a number that can be stale and nobody can tell.
    /// </summary>
    internal procedure InitCue()
    begin
        Rec.Reset();
        if Rec.Get() then
            exit;

        Rec.Init();
        Rec.Insert();
    end;
}
