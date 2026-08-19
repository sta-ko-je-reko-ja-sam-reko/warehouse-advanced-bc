namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

page 50300 "WHA Slotting Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "WHA Slotting Setup";
    Caption = 'Slotting setup';
    InsertAllowed = false;
    DeleteAllowed = false;
    AdditionalSearchTerms = 'slotting, ABC, velocity, re-slotting, bin ranking';

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
            group(Analysis)
            {
                Caption = 'Working out how fast things move';

                field(Basis; Rec.Basis)
                {
                    ApplicationArea = WHASlotting;
                }
                field(BasisDescription; BasisDescription)
                {
                    Caption = 'What that means';
                    ToolTip = 'Specifies what the chosen basis ranks items on.';
                    Editable = false;
                    MultiLine = true;
                    ApplicationArea = WHASlotting;
                }
                field("Analysis Period Days"; Rec."Analysis Period Days")
                {
                    ApplicationArea = WHASlotting;
                }
                field("Min Movements"; Rec."Min Movements")
                {
                    ApplicationArea = WHASlotting;
                }
                field("Class A Percent"; Rec."Class A Percent")
                {
                    ApplicationArea = WHASlotting;
                }
                field("Class B Percent"; Rec."Class B Percent")
                {
                    ApplicationArea = WHASlotting;
                }
            }
            group(Placement)
            {
                Caption = 'Where each class belongs';

                field("Class A Min Bin Ranking"; Rec."Class A Min Bin Ranking")
                {
                    ApplicationArea = WHASlotting;
                }
                field("Class B Min Bin Ranking"; Rec."Class B Min Bin Ranking")
                {
                    ApplicationArea = WHASlotting;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenVelocities)
            {
                Caption = 'Item velocity';
                ToolTip = 'Specifies the action that opens the measured movement per item.';
                Image = Statistics;
                ApplicationArea = WHASlotting;
                RunObject = page "WHA Item Velocities";
            }
            action(OpenProposals)
            {
                Caption = 'Slotting proposals';
                ToolTip = 'Specifies the action that opens the proposed moves.';
                Image = List;
                ApplicationArea = WHASlotting;
                RunObject = page "WHA Slotting Proposals";
            }
        }
    }

    trigger OnOpenPage()
    var
        SlotFeatureSetup: Codeunit "WHA Slot. Feature Setup";
    begin
        SlotFeatureSetup.EnsureSetup(Rec);
        OpeningEnabled := Rec."WHA Enabled";
    end;

    trigger OnAfterGetRecord()
    begin
        DescribeBasis();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ApplyEnabledChangeIfNeeded();
        exit(true);
    end;

    var
        OpeningEnabled: Boolean;
        BasisDescription: Text;

    local procedure DescribeBasis()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        BasisDescription := SlottingMgt.DescribeBasis();
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
