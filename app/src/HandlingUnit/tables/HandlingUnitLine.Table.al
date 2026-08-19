namespace WarehouseAdvanced.HandlingUnit;

using Microsoft.Inventory.Item;

table 50052 "WHA Handling Unit Line"
{
    Caption = 'Handling unit line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Handling Unit No."; Code[20])
        {
            Caption = 'Handling unit no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the handling unit that holds these goods.';
            TableRelation = "WHA Handling Unit"."No.";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the position of the line within the handling unit.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item held in the handling unit.';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                Logic().Validate_ItemNo(Rec, xRec);
            end;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant held in the handling unit.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the goods on this line are.';
        }
        field(20; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of measure code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unit the quantity is counted in.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much of the item the handling unit holds.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Logic().Validate_Quantity(Rec, xRec);
            end;
        }
        field(30; "Lot No."; Code[50])
        {
            Caption = 'Lot no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the lot the goods on this line belong to.';
        }
        field(31; "Serial No."; Code[50])
        {
            Caption = 'Serial no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the serial number of the goods on this line.';
        }
    }

    keys
    {
        key(PK; "Handling Unit No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Quantity;
        }
        key(Item; "Item No.", "Variant Code")
        {
            SumIndexFields = Quantity;
        }
        key(Lot; "Lot No.")
        {
        }
        key(Serial; "Serial No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", Description, Quantity)
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    var
        ILogic: Interface "WHA IHandlingUnitLine";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the handling unit line logic. Used by tests to supply a
    /// fake and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IHandlingUnitLine")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IHandlingUnitLine"
    var
        DefaultLogic: Codeunit "WHA HU Line Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
