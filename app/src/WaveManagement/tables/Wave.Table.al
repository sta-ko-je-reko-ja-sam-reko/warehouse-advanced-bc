namespace WarehouseAdvanced.WaveManagement;

using Microsoft.Inventory.Location;
using WarehouseAdvanced.DirectedWork;

table 50151 "WHA Wave"
{
    Caption = 'Wave';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Waves";
    DrillDownPageId = "WHA Waves";
    DataCaptionFields = "No.", Description;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies the wave.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what this wave is for, such as the shift or the departure it belongs to.';
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location whose work this wave gathers. Only work at that location is picked up.';
            TableRelation = Location;
        }
        field(20; Status; Enum "WHA Wave Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the wave is in its life. An open wave is still being built; a released one is on the floor.';
            Editable = false;
        }
        field(30; Strategy; Enum "WHA Wave Strategy")
        {
            Caption = 'Strategy';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the wave chooses which work to gather when it is filled.';
        }
        field(31; "Max Tasks"; Integer)
        {
            Caption = 'Max tasks';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many jobs this wave takes when it is filled. Zero uses the number from the wave setup.';
            MinValue = 0;
        }
        field(40; "Released At"; DateTime)
        {
            Caption = 'Released at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the wave was sent to the floor.';
            Editable = false;
        }
        field(41; "Completed At"; DateTime)
        {
            Caption = 'Completed at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the last job in the wave was finished.';
            Editable = false;
        }
        field(50; "Task Count"; Integer)
        {
            Caption = 'Jobs';
            ToolTip = 'Specifies how many jobs the wave holds.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Warehouse Task" where("Wave No." = field("No.")));
            Editable = false;
        }
        field(51; "Completed Task Count"; Integer)
        {
            Caption = 'Jobs finished';
            ToolTip = 'Specifies how many of the wave''s jobs are finished. It counts cancelled jobs too, because they are no longer outstanding.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Warehouse Task" where("Wave No." = field("No."), Status = filter(WHACompleted | WHACancelled)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Placement; "Location Code", Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, Status)
        {
        }
        fieldgroup(Brick; "No.", Description, "Location Code", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    trigger OnDelete()
    begin
        Logic().Trigger_OnDelete(Rec);
    end;

    var
        ILogic: Interface "WHA IWave";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the wave logic. Used by tests to supply a fake and by
    /// dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IWave")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IWave"
    var
        DefaultLogic: Codeunit "WHA Wave Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
