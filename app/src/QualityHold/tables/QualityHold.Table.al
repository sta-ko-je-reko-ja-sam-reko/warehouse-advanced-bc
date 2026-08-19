namespace WarehouseAdvanced.QualityHold;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;
using WarehouseAdvanced.HandlingUnit;

table 50551 "WHA Quality Hold"
{
    Caption = 'Quality hold';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Quality Holds";
    DrillDownPageId = "WHA Quality Holds";
    DataCaptionFields = "Entry No.", "Handling Unit No.";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies this hold.';
            AutoIncrement = true;
        }
        field(10; "Handling Unit No."; Code[20])
        {
            Caption = 'Handling unit no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the handling unit that was stopped from being used.';
            TableRelation = "WHA Handling Unit"."No.";
            NotBlank = true;
            Editable = false;
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the goods were standing when the hold was placed. It is a snapshot, so it does not follow the unit afterwards.';
            TableRelation = Location;
            Editable = false;
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the goods were in when the hold was placed. It is a snapshot, so it does not follow the unit afterwards.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            Editable = false;
        }
        field(20; Reason; Enum "WHA Hold Reason")
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies why the goods were stopped.';
        }
        field(21; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what was found, in the words of whoever found it.';
        }
        field(30; Status; Enum "WHA Hold Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the goods are still stopped or the hold has been lifted.';
            Editable = false;
        }
        field(40; Disposition; Enum "WHA Hold Disposition")
        {
            Caption = 'Disposition';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what happens to the goods. It is decided while the hold is on, and applied when the hold is released.';

            trigger OnValidate()
            begin
                Logic().Validate_Disposition(Rec, xRec);
            end;
        }
        field(41; "Cascaded From Entry No."; Integer)
        {
            Caption = 'Held with';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the hold that brought this one with it, when the unit was inside another unit that was stopped. Blank means the unit was stopped in its own right.';
            TableRelation = "WHA Quality Hold"."Entry No.";
            Editable = false;
        }
        field(50; "Held By User ID"; Code[50])
        {
            Caption = 'Held by';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who stopped the goods.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(51; "Held At"; DateTime)
        {
            Caption = 'Held at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the goods were stopped.';
            Editable = false;
        }
        field(52; "Released By User ID"; Code[50])
        {
            Caption = 'Released by';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who lifted the hold. It is deliberately recorded separately from who placed it.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(53; "Released At"; DateTime)
        {
            Caption = 'Released at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the hold was lifted.';
            Editable = false;
        }
        field(60; "Previous Unit Status"; Enum "WHA Handling Unit Status")
        {
            Caption = 'Status before the hold';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the handling unit was before it was stopped. Releasing the goods back into stock puts it back to this.';
            Editable = false;
        }
        field(70; Posted; Boolean)
        {
            Caption = 'Posted';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the goods this hold covers were written off in the item ledger. A write-off left in an item journal for somebody to look at has not been posted.';
            Editable = false;
        }
        field(71; "Posting Document No."; Code[20])
        {
            Caption = 'Posting document no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the document number the write-off was raised under, so a ledger entry can be traced back to the hold that caused it.';
            Editable = false;
        }
        field(72; "Posted At"; DateTime)
        {
            Caption = 'Posted at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the write-off was handed to the posting method.';
            Editable = false;
        }
        field(73; "Posted Quantity"; Decimal)
        {
            Caption = 'Posted quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much stock the write-off covered, summed over everything the handling unit was holding when the hold was lifted.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Unit; "Handling Unit No.", Status)
        {
        }
        key(Outstanding; Status, Reason)
        {
        }
        key(Cascade; "Cascaded From Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Handling Unit No.", Status)
        {
        }
        fieldgroup(Brick; "Entry No.", "Handling Unit No.", Reason, Status)
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
        ILogic: Interface "WHA IQualityHold";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the quality hold logic. Used by tests to supply a fake and
    /// by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IQualityHold")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IQualityHold"
    var
        DefaultLogic: Codeunit "WHA Quality Hold Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
