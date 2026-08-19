namespace WarehouseAdvanced.Replenishment;

page 50251 "WHA Replenishment Rules"
{
    PageType = List;
    ApplicationArea = WHAReplenishment;
    UsageCategory = Lists;
    SourceTable = "WHA Replenishment Rule";
    Caption = 'Replenishment rules';
    CardPageId = "WHA Repl. Rule Card";

    layout
    {
        area(Content)
        {
            repeater(Rules)
            {
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                }
                field("Maximum Quantity"; Rec."Maximum Quantity")
                {
                }
                field(Method; Rec.Method)
                {
                }
                field("Source Bin Code"; Rec."Source Bin Code")
                {
                }
                field(Priority; Rec.Priority)
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
                field("Last Checked At"; Rec."Last Checked At")
                {
                }
                field("Last Task No."; Rec."Last Task No.")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunReplenishment)
            {
                Caption = 'Replenish now';
                ToolTip = 'Specifies the action that measures every rule and raises the work needed to top up the bins that have run low. A bin that already has replenishment work outstanding is left alone.';
                Image = Refresh;

                trigger OnAction()
                begin
                    RunForEveryLocation();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RunReplenishmentRef; RunReplenishment)
                {
                }
            }
        }
    }

    var
        RaisedMsg: Label '%1 piece(s) of replenishment work raised.', Comment = '%1 = how many warehouse tasks were created';

    local procedure RunForEveryLocation()
    var
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        Message(RaisedMsg, ReplenishmentMgt.Run(''));
        CurrPage.Update(false);
    end;
}
