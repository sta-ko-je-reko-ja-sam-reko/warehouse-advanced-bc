namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

tableextension 50251 "WHA Repl Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(50250; "WHA Repl. Rules Blocked"; Integer)
        {
            Caption = 'Replenishment rules switched off';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many replenishment rules are blocked, and so are looking after no bin at all.';
            Editable = false;
        }
    }
}
