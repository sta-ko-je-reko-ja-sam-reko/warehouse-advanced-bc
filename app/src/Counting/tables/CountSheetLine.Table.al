namespace WarehouseAdvanced.Counting;

using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;
using WarehouseAdvanced.HandlingUnit;

table 50502 "WHA Count Sheet Line"
{
    Caption = 'Count sheet line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Sheet No."; Code[20])
        {
            Caption = 'Sheet no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the count sheet this line belongs to.';
            TableRelation = "WHA Count Sheet"."No.";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the position of the line within the count sheet.';
        }
        field(10; "Bin Code"; Code[20])
        {
            Caption = 'Bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin being counted.';
            TableRelation = Bin.Code;
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item being counted.';
            TableRelation = Item."No.";
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant being counted.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of measure code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unit the count is entered in.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(14; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what is being counted on this line.';
        }
        field(15; "Handling Unit No."; Code[20])
        {
            Caption = 'Handling unit no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the handling unit whose contents this line covers, when the sheet counts units rather than bins.';
            TableRelation = "WHA Handling Unit"."No.";
        }
        field(20; "Expected Quantity"; Decimal)
        {
            Caption = 'Expected quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the system believed was there when the sheet was filled. On a blind sheet it is hidden until the sheet has been counted.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; "Counted Quantity"; Decimal)
        {
            Caption = 'Counted quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what was actually found. Entering it counts the line, works out the difference, and stamps who counted it and when.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Logic().Validate_CountedQuantity(Rec, xRec);
            end;
        }
        field(22; Counted; Boolean)
        {
            Caption = 'Counted';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this line has been counted. A count of zero is still a count.';
            Editable = false;
        }
        field(23; Variance; Decimal)
        {
            Caption = 'Difference';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far the count came out from what was expected. A positive number means more was found than expected.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(24; "Out of Tolerance"; Boolean)
        {
            Caption = 'Out of tolerance';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the difference is bigger than the counting setup allows, in which case somebody has to approve it before the sheet can be closed.';
            Editable = false;
        }
        field(25; Approved; Boolean)
        {
            Caption = 'Approved';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether somebody has accepted a difference that is out of tolerance. Counting the line again withdraws the approval, because it is a new number.';
            Editable = false;
        }
        field(30; "Counted By User ID"; Code[50])
        {
            Caption = 'Counted by user ID';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who counted the line.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(31; "Counted At"; DateTime)
        {
            Caption = 'Counted at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the line was counted.';
            Editable = false;
        }
        field(32; "Approved By User ID"; Code[50])
        {
            Caption = 'Approved by user ID';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who approved the difference on this line.';
            TableRelation = User."User Name";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Sheet No.", "Line No.")
        {
            Clustered = true;
        }
        key(Counted; "Sheet No.", Counted)
        {
        }
        key(Item; "Item No.", "Variant Code")
        {
        }
        key(HandlingUnit; "Handling Unit No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Bin Code", "Item No.", "Counted Quantity")
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
        ILogic: Interface "WHA ICountSheetLine";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the count sheet line logic. Used by tests to supply a fake
    /// and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA ICountSheetLine")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA ICountSheetLine"
    var
        DefaultLogic: Codeunit "WHA Count Line Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
