namespace WarehouseAdvanced.Slotting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;
using WarehouseAdvanced.DirectedWork;

table 50302 "WHA Slotting Proposal"
{
    Caption = 'Slotting proposal';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Slotting Proposals";
    DrillDownPageId = "WHA Slotting Proposals";
    DataCaptionFields = "Entry No.", "Item No.";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies this proposal.';
            AutoIncrement = true;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the proposal is about.';
            TableRelation = Location;
            Editable = false;
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item that is in the wrong sort of bin.';
            TableRelation = Item."No.";
            Editable = false;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant the proposal is about.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(20; Class; Enum "WHA Velocity Class")
        {
            Caption = 'Class';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how fast the item moves, which is what makes its bin the wrong one.';
            Editable = false;
        }
        field(21; "From Bin Code"; Code[20])
        {
            Caption = 'Now picked from';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the item is picked from most often today.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            Editable = false;
        }
        field(22; "From Bin Ranking"; Integer)
        {
            Caption = 'Ranking of that bin';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the ranking of the bin it is picked from now.';
            Editable = false;
        }
        field(23; "Required Bin Ranking"; Integer)
        {
            Caption = 'Ranking its class deserves';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the ranking the slotting setup says this class should have.';
            Editable = false;
        }
        field(24; "To Bin Code"; Code[20])
        {
            Caption = 'Move it to';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the goods should go. The app does not choose this: it says a move is worth making, and somebody who knows the warehouse says where to. Fill it in before accepting and the work is raised for you.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(30; Status; Enum "WHA Proposal Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether anybody has answered the proposal yet.';
            Editable = false;
        }
        field(31; Reason; Text[100])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies why the proposal was made.';
            Editable = false;
        }
        field(40; "Created At"; DateTime)
        {
            Caption = 'Created at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the proposal was made. A proposal is only as good as the analysis behind it, so an old one is worth re-running rather than acting on.';
            Editable = false;
        }
        field(41; "Handled By User ID"; Code[50])
        {
            Caption = 'Answered by';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who accepted or rejected the proposal.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(42; "Handled At"; DateTime)
        {
            Caption = 'Answered at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the proposal was answered.';
            Editable = false;
        }
        field(50; "Task No."; Code[20])
        {
            Caption = 'Task no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the warehouse job raised to make the move, when the proposal was accepted with somewhere to move to.';
            TableRelation = "WHA Warehouse Task"."No.";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Outstanding; "Location Code", Status)
        {
        }
        key(Item; "Item No.", "Variant Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Item No.", Status)
        {
        }
        fieldgroup(Brick; "Entry No.", "Item No.", Class, Status)
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
        ILogic: Interface "WHA ISlottingProposal";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the slotting proposal logic. Used by tests to supply a fake
    /// and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA ISlottingProposal")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA ISlottingProposal"
    var
        DefaultLogic: Codeunit "WHA Slotting Prop. Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
