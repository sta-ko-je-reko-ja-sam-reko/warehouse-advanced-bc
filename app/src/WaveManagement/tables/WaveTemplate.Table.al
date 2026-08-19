namespace WarehouseAdvanced.WaveManagement;

using Microsoft.Inventory.Location;

table 50152 "WHA Wave Template"
{
    Caption = 'Wave template';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Wave Templates";
    DrillDownPageId = "WHA Wave Templates";
    DataCaptionFields = "Code", Description;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code that identifies the template, such as the round or the shift it builds a wave for.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what this template builds, such as the morning pick round. Every wave it creates is described the same way.';
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the waves built from this template gather work at. A template covers one location.';
            TableRelation = Location;
        }
        field(20; Strategy; Enum "WHA Wave Strategy")
        {
            Caption = 'Strategy';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the waves built from this template choose which work to gather.';
        }
        field(30; "Max Tasks"; Integer)
        {
            Caption = 'Max jobs';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many jobs a wave from this template takes. Zero uses the number from the wave setup.';
            MinValue = 0;
        }
        field(31; "Max Minutes"; Decimal)
        {
            Caption = 'Max minutes of work';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much work, measured in minutes, a wave from this template takes. It is worked out from the labour standards, so it limits nothing until somebody has written them. Zero means the job count is the only limit.';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(40; "Release Automatically"; Boolean)
        {
            Caption = 'Release the wave when it is built';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a wave built from this template goes to the floor as soon as it has gathered its work. Leave this off if somebody should look at what was gathered first.';
        }
        field(41; Scheduled; Boolean)
        {
            Caption = 'Include in the scheduled run';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the scheduled run builds a wave from this template. The run itself is a job queue entry, so when and how often it happens is set up there rather than here.';
        }
        field(42; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this template is out of use. A blocked template builds nothing, by hand or on a schedule, and is kept rather than deleted so the waves it already built still name something.';
        }
        field(50; "Last Run At"; DateTime)
        {
            Caption = 'Last run at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when this template last ran, whether or not it found anything to gather.';
            Editable = false;
        }
        field(51; "Last Wave No."; Code[20])
        {
            Caption = 'Last wave no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last wave this template built. It stays empty when the last run found nothing to gather.';
            TableRelation = "WHA Wave"."No.";
            Editable = false;
        }
        field(60; "Wave Count"; Integer)
        {
            Caption = 'Waves built';
            ToolTip = 'Specifies how many waves have been built from this template.';
            FieldClass = FlowField;
            CalcFormula = count("WHA Wave" where("Template Code" = field("Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(Run; Scheduled, Blocked, "Location Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Location Code")
        {
        }
        fieldgroup(Brick; "Code", Description, "Location Code", Strategy)
        {
        }
    }

    trigger OnDelete()
    begin
        Logic().Trigger_OnDelete(Rec);
    end;

    var
        ILogic: Interface "WHA IWaveTemplate";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the wave template logic. Used by tests to supply a fake
    /// and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IWaveTemplate")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IWaveTemplate"
    var
        DefaultLogic: Codeunit "WHA Wave Template Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
