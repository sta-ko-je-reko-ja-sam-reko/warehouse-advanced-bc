namespace WarehouseAdvanced.Slotting;

page 50301 "WHA Item Velocities"
{
    PageType = List;
    ApplicationArea = WHASlotting;
    UsageCategory = Lists;
    SourceTable = "WHA Item Velocity";
    Caption = 'Item velocity';
    Editable = false;
    SourceTableView = sorting("Location Code", "Rank Value") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Velocities)
            {
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field(Class; Rec.Class)
                {
                    StyleExpr = ClassStyle;
                }
                field(Movements; Rec.Movements)
                {
                }
                field("Quantity Moved"; Rec."Quantity Moved")
                {
                }
                field("Rank Value"; Rec."Rank Value")
                {
                }
                field("Main Bin Code"; Rec."Main Bin Code")
                {
                }
                field("Main Bin Ranking"; Rec."Main Bin Ranking")
                {
                }
                field("From Date"; Rec."From Date")
                {
                }
                field("To Date"; Rec."To Date")
                {
                }
                field("Calculated At"; Rec."Calculated At")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AnalyseLocation)
            {
                Caption = 'Work out velocity';
                ToolTip = 'Specifies the action that measures how fast every item moves at the location this list is filtered to, from the picking already done, and gives each one a class.';
                Image = Calculate;

                trigger OnAction()
                begin
                    ApplyAnalyse();
                end;
            }
            action(ProposeMoves)
            {
                Caption = 'Propose moves';
                ToolTip = 'Specifies the action that proposes a move for every item picked from a bin worse than its class deserves.';
                Image = SuggestLines;

                trigger OnAction()
                begin
                    ApplyPropose();
                end;
            }
        }
        area(Navigation)
        {
            action(ShowProposals)
            {
                Caption = 'Slotting proposals';
                ToolTip = 'Specifies the action that opens the proposed moves.';
                Image = List;
                RunObject = page "WHA Slotting Proposals";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AnalyseLocationRef; AnalyseLocation)
                {
                }
                actionref(ProposeMovesRef; ProposeMoves)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetClassStyle();
    end;

    var
        ClassStyle: Text;
        AnalysedMsg: Label '%1 item(s) measured at %2.', Comment = '%1 = how many items were measured, %2 = the location code';
        ProposedMsg: Label '%1 move(s) proposed at %2.', Comment = '%1 = how many proposals were made, %2 = the location code';
        NoLocationErr: Label 'Filter the list to one location first. Velocity compares the items at one site against each other, so it cannot be worked out for all of them at once.';

    local procedure ApplyAnalyse()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
        LocationCode: Code[10];
    begin
        LocationCode := FilteredLocation();
        Message(AnalysedMsg, SlottingMgt.Analyse(LocationCode, 0D, 0D), LocationCode);
        CurrPage.Update(false);
    end;

    local procedure ApplyPropose()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
        LocationCode: Code[10];
    begin
        LocationCode := FilteredLocation();
        Message(ProposedMsg, SlottingMgt.Propose(LocationCode), LocationCode);
    end;

    local procedure FilteredLocation(): Code[10]
    begin
        if Rec.GetFilter("Location Code") = '' then
            Error(NoLocationErr);
        exit(CopyStr(Rec.GetRangeMin("Location Code"), 1, 10));
    end;

    local procedure SetClassStyle()
    begin
        case Rec.Class of
            Rec.Class::WHAClassA:
                ClassStyle := 'Favorable';
            Rec.Class::WHAClassC:
                ClassStyle := 'Subordinate';
            else
                ClassStyle := 'Standard';
        end;
    end;
}
