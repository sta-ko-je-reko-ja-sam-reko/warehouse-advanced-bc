namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;
using WarehouseAdvanced.HandlingUnit;

table 50201 "WHA Warehouse Task"
{
    Caption = 'Warehouse task';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Warehouse Tasks";
    DrillDownPageId = "WHA Warehouse Tasks";
    DataCaptionFields = "No.", Description;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies the warehouse task.';
            NotBlank = true;
        }
        field(2; "Task Type"; Enum "WHA Warehouse Task Type")
        {
            Caption = 'Task type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the kind of work the task asks for, such as a put-away or a pick.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the operator is being asked to do.';
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location the work takes place at.';
            TableRelation = Location;

            trigger OnValidate()
            begin
                Logic().Validate_LocationCode(Rec, xRec);
            end;
        }
        field(11; "From Bin Code"; Code[20])
        {
            Caption = 'From bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the goods are taken from.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(12; "To Bin Code"; Code[20])
        {
            Caption = 'To bin code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bin the goods are taken to. Completing the task moves the handling unit to this bin.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(20; "Handling Unit No."; Code[20])
        {
            Caption = 'Handling unit no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the handling unit the work moves. Everything on the unit moves with it.';
            TableRelation = "WHA Handling Unit"."No.";

            trigger OnValidate()
            begin
                Logic().Validate_HandlingUnitNo(Rec, xRec);
            end;
        }
        field(21; "Item No."; Code[20])
        {
            Caption = 'Item no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item the work moves, when the task is not about a whole handling unit.';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                Logic().Validate_ItemNo(Rec, xRec);
            end;
        }
        field(22; "Variant Code"; Code[10])
        {
            Caption = 'Variant code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant the work moves.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(23; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much of the item the work moves.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Logic().Validate_Quantity(Rec, xRec);
            end;
        }
        field(24; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of measure code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the unit the quantity is counted in.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(30; Status; Enum "WHA Warehouse Task Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the task is in its life cycle. The status changes through the actions on the task, not by typing.';
            Editable = false;
        }
        field(31; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how urgent the task is. A lower number is more urgent, so it is offered to an operator first.';
            MinValue = 0;

            trigger OnValidate()
            begin
                Logic().Validate_Priority(Rec, xRec);
            end;
        }
        field(32; "Due Date"; Date)
        {
            Caption = 'Due date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date the work is needed by. Tasks of the same priority are offered in due date order.';
        }
        field(40; "Assigned To User ID"; Code[50])
        {
            Caption = 'Assigned to user ID';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the person the task is assigned to. Clearing this returns the task to the queue.';
            TableRelation = User."User Name";

            trigger OnValidate()
            begin
                Logic().Validate_AssignedToUserID(Rec, xRec);
            end;
        }
        field(41; "Assigned At"; DateTime)
        {
            Caption = 'Assigned at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the task was assigned to the person working it.';
            Editable = false;
        }
        field(42; "Started At"; DateTime)
        {
            Caption = 'Started at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the operator started the task.';
            Editable = false;
        }
        field(43; "Completed At"; DateTime)
        {
            Caption = 'Completed at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the task was completed.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Queue; Status, "Location Code", Priority, "Due Date")
        {
        }
        key(Assignment; "Assigned To User ID", Status, Priority)
        {
        }
        key(HandlingUnit; "Handling Unit No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, Status)
        {
        }
        fieldgroup(Brick; "No.", "Task Type", Description, Status)
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
        ILogic: Interface "WHA IWarehouseTask";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the warehouse task logic. Used by tests to supply a fake
    /// and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IWarehouseTask")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IWarehouseTask"
    var
        DefaultLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
