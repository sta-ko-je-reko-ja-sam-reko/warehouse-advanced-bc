namespace WarehouseAdvanced.Core;

using Microsoft.Foundation.NoSeries;

table 50000 "WHA Warehouse Setup"
{
    Caption = 'Warehouse advanced setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary key';
            DataClassification = CustomerContent;
        }
        field(10; "Handling Unit Nos."; Code[20])
        {
            Caption = 'Handling unit nos.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series used to assign numbers to handling units.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                Logic().Validate_HandlingUnitNos(Rec, xRec);
            end;
        }
        field(20; "Warehouse Task Nos."; Code[20])
        {
            Caption = 'Warehouse task nos.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series used to assign numbers to warehouse tasks.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                Logic().Validate_WarehouseTaskNos(Rec, xRec);
            end;
        }
        field(30; "Wave Nos."; Code[20])
        {
            Caption = 'Wave nos.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series used to assign numbers to waves.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                Logic().Validate_WaveNos(Rec, xRec);
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        ILogic: Interface "WHA IWarehouseSetup";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the setup logic. Used by tests to supply a fake and by
    /// dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IWarehouseSetup")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IWarehouseSetup"
    var
        DefaultLogic: Codeunit "WHA Warehouse Setup Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
