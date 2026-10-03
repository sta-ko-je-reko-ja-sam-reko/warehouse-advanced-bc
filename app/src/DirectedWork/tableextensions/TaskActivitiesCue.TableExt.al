namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

tableextension 55201 "WHA Task Activities Cue" extends "WHA Activities Cue"
{
    fields
    {
        field(55200; "WHA Tasks Waiting"; Integer)
        {
            Caption = 'Jobs waiting';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many jobs are on the floor with nobody holding them.';
            Editable = false;
        }
        field(55201; "WHA Tasks In Progress"; Integer)
        {
            Caption = 'Jobs being done';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many jobs somebody has started and not yet finished.';
            Editable = false;
        }
        field(55202; "WHA Tasks Overdue"; Integer)
        {
            Caption = 'Jobs past their date';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how many unfinished jobs were wanted before today.';
            Editable = false;
        }
    }
}
