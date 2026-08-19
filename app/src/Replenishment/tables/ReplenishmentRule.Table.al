namespace WarehouseAdvanced.Replenishment;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using WarehouseAdvanced.DirectedWork;

table 50251 "WHA Replenishment Rule"
{
    Caption = 'Replenishment rule';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Replenishment Rules";
    DrillDownPageId = "WHA Replenishment Rules";
    DataCaptionFields = "Location Code", "Item No.", "Bin Code";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the rule looks after.';
            TableRelation = Location;
            NotBlank = true;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item the bin is kept stocked with.';
            TableRelation = Item."No.";
            NotBlank = true;

            trigger OnValidate()
            begin
                Logic().Validate_ItemNo(Rec, xRec);
            end;
        }
        field(3; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant the bin is kept stocked with. Leave it blank when the item has no variants.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(4; "Bin Code"; Code[20])
        {
            Caption = 'Bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin that is kept stocked. This is the bin people pick from, not the bin the goods come from.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what this rule is for, such as the pick face it keeps full.';
        }
        field(11; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of measure code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unit the minimum and maximum are counted in.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(20; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how low the bin may run before it is topped up. A minimum of zero never asks for anything, which is how a rule is written down without being acted on.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                Logic().Validate_MinimumQuantity(Rec, xRec);
            end;
        }
        field(21; "Maximum Quantity"; Decimal)
        {
            Caption = 'Maximum quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how full the bin is topped up to. The work a run raises asks for the difference between what is there and this number.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                Logic().Validate_MaximumQuantity(Rec, xRec);
            end;
        }
        field(30; Method; Enum "WHA Repl. Method")
        {
            Caption = 'Method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the rule measures what is in the bin right now.';
        }
        field(31; "Source Bin Code"; Code[20])
        {
            Caption = 'Source bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the goods are fetched from. Leave it blank to let whoever does the work decide where to take them from.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(32; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how urgent the work this rule raises is. A lower number is more urgent. Zero uses the number from the replenishment setup.';
            MinValue = 0;
        }
        field(40; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the rule is skipped by a run. Use this to stop a rule asking for work without losing what it says.';
        }
        field(50; "Last Checked At"; DateTime)
        {
            Caption = 'Last checked at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when a run last measured this bin.';
            Editable = false;
        }
        field(51; "Last Task No."; Code[20])
        {
            Caption = 'Last task no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last piece of work this rule raised.';
            TableRelation = "WHA Warehouse Task"."No.";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Location Code", "Item No.", "Variant Code", "Bin Code")
        {
            Clustered = true;
        }
        key(Item; "Item No.", "Variant Code")
        {
        }
        key(Bin; "Location Code", "Bin Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Location Code", "Bin Code", "Item No.")
        {
        }
        fieldgroup(Brick; "Item No.", "Bin Code", "Minimum Quantity", "Maximum Quantity")
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    var
        ILogic: Interface "WHA IReplenishment";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the replenishment rule logic. Used by tests to supply a
    /// fake and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IReplenishment")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IReplenishment"
    var
        DefaultLogic: Codeunit "WHA Repl. Rule Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
