namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

page 50450 "WHA Dock Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Dock Setup";
    Caption = 'Dock and yard setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'dock, door, yard, trailer, appointment, slot booking';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("WHA Enabled"; Rec."WHA Enabled")
                {
                }
            }
            group(Booking)
            {
                Caption = 'Booking vehicles in';

                field("Door Selection"; Rec."Door Selection")
                {
                    ApplicationArea = WHADockYard;
                }
                field(SelectionDescription; SelectionDescription)
                {
                    Caption = 'What that means';
                    ToolTip = 'Specifies how the chosen strategy picks a door.';
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = WHADockYard;
                }
                field("Default Slot Minutes"; Rec."Default Slot Minutes")
                {
                    ApplicationArea = WHADockYard;
                }
                field("Late Threshold Minutes"; Rec."Late Threshold Minutes")
                {
                    ApplicationArea = WHADockYard;
                }
            }
            group(Yard)
            {
                Caption = 'The yard';

                field("Require Yard Position"; Rec."Require Yard Position")
                {
                    ApplicationArea = WHADockYard;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenDoors)
            {
                Caption = 'Dock doors';
                ToolTip = 'Specifies the action that opens the doors this site has.';
                Image = Bins;
                ApplicationArea = WHADockYard;
                RunObject = page "WHA Dock Doors";
            }
            action(OpenPositions)
            {
                Caption = 'Yard positions';
                ToolTip = 'Specifies the action that opens the places a trailer can be parked.';
                Image = Lot;
                ApplicationArea = WHADockYard;
                RunObject = page "WHA Yard Positions";
            }
            action(OpenAppointments)
            {
                Caption = 'Dock appointments';
                ToolTip = 'Specifies the action that opens the vehicles booked in.';
                Image = List;
                ApplicationArea = WHADockYard;
                RunObject = page "WHA Dock Appointments";
            }
        }
    }

    trigger OnOpenPage()
    var
        DockFeatureSetup: Codeunit "WHA Dock Feature Setup";
    begin
        DockFeatureSetup.EnsureSetup(Rec);
        OpeningEnabled := Rec."WHA Enabled";
    end;

    trigger OnAfterGetRecord()
    begin
        DescribeSelection();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    var
        OpeningEnabled: Boolean;
        SelectionDescription: Text;

    local procedure DescribeSelection()
    var
        DockMgt: Codeunit "WHA Dock Mgt.";
    begin
        SelectionDescription := DockMgt.DescribeSelection();
    end;

    local procedure ApplyEnabledChangeIfNeeded()
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
    begin
        if not Rec.Get() then
            exit;
        if Rec."WHA Enabled" = OpeningEnabled then
            exit;

        FeatureMgt.ApplyExperienceChange();
    end;
}
