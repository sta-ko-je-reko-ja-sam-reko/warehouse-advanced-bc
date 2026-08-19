namespace WarehouseAdvanced.LabourManagement;

using Microsoft.Inventory.Location;
using System.Security.AccessControl;
using WarehouseAdvanced.DirectedWork;

table 50352 "WHA Labour Entry"
{
    Caption = 'Labour entry';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Labour Entries";
    DrillDownPageId = "WHA Labour Entries";
    DataCaptionFields = "Entry No.", "User ID";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies this piece of recorded time.';
            AutoIncrement = true;
        }
        field(10; "Entry Type"; Enum "WHA Labour Entry Type")
        {
            Caption = 'Entry type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the time was spent on a warehouse job or on something else.';
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies whose time this is.';
            TableRelation = User."User Name";
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies where the time was spent.';
            TableRelation = Location;
        }
        field(13; "Posting Date"; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the day the time belongs to. It is taken from when the work finished.';
        }
        field(20; "Task No."; Code[20])
        {
            Caption = 'Task no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the warehouse job the time was spent on. It is blank on time that was not spent on a job.';
            TableRelation = "WHA Warehouse Task"."No.";
            Editable = false;
        }
        field(21; "Task Type"; Enum "WHA Warehouse Task Type")
        {
            Caption = 'Task type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the kind of work the time was spent on.';
            Editable = false;
        }
        field(22; "Quantity Handled"; Decimal)
        {
            Caption = 'Quantity handled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how much was moved in the time recorded.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(30; "Indirect Reason"; Enum "WHA Indirect Reason")
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the time was spent on when it was not spent on a job.';
        }
        field(31; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the time was spent on, in the words of whoever recorded it.';
        }
        field(40; "Started At"; DateTime)
        {
            Caption = 'Started at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the time started.';
            Editable = false;
        }
        field(41; "Ended At"; DateTime)
        {
            Caption = 'Ended at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the time ended.';
            Editable = false;
        }
        field(42; "Actual Minutes"; Decimal)
        {
            Caption = 'Actual minutes';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long it actually took.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Logic().Validate_ActualMinutes(Rec, xRec);
            end;
        }
        field(43; "Expected Minutes"; Decimal)
        {
            Caption = 'Expected minutes';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how long the standard says it should have taken. It is blank where no standard applied.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(44; "Performance Percent"; Decimal)
        {
            Caption = 'Performance percent';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the expected time as a percentage of the actual time. A hundred is exactly to standard, more than a hundred is faster than standard. It is blank where no standard applied.';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
        field(50; "Measured Against Standard"; Boolean)
        {
            Caption = 'Measured';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether a standard applied to this time. Time that nothing measured is kept and counted, but it is not counted as performance.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Task; "Task No.")
        {
        }
        key(Person; "User ID", "Posting Date")
        {
            SumIndexFields = "Actual Minutes", "Expected Minutes";
        }
        key(Placement; "Location Code", "Posting Date", "Entry Type")
        {
            SumIndexFields = "Actual Minutes", "Expected Minutes";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "User ID", "Actual Minutes")
        {
        }
        fieldgroup(Brick; "Entry No.", "User ID", "Entry Type", "Actual Minutes")
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    var
        ILogic: Interface "WHA ILabourEntry";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the labour entry logic. Used by tests to supply a fake and
    /// by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA ILabourEntry")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA ILabourEntry"
    var
        DefaultLogic: Codeunit "WHA Labour Entry Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
