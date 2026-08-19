namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.DirectedWork;

page 50252 "WHA Repl. Rule Card"
{
    PageType = Card;
    ApplicationArea = WHAReplenishment;
    UsageCategory = None;
    SourceTable = "WHA Replenishment Rule";
    Caption = 'Replenishment rule';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
            }
            group(Levels)
            {
                Caption = 'How full the bin is kept';

                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                }
                field("Maximum Quantity"; Rec."Maximum Quantity")
                {
                }
                field(Method; Rec.Method)
                {
                }
                field(MethodDescription; MethodDescription)
                {
                    Caption = 'Where the measurement comes from';
                    ToolTip = 'Specifies what this method looks at when it measures the bin.';
                    Editable = false;
                    MultiLine = true;
                }
                field(InTheBinNow; InTheBinNow)
                {
                    Caption = 'In the bin now';
                    ToolTip = 'Specifies how much of the item the rule believes is in the bin at this moment.';
                    Editable = false;
                    DecimalPlaces = 0 : 5;
                }
                field(WouldAskFor; WouldAskFor)
                {
                    Caption = 'Would ask for';
                    ToolTip = 'Specifies how much a run would ask for right now. Zero means the bin has enough.';
                    Editable = false;
                    DecimalPlaces = 0 : 5;
                }
            }
            group(Work)
            {
                Caption = 'The work it raises';

                field("Source Bin Code"; Rec."Source Bin Code")
                {
                }
                field(Priority; Rec.Priority)
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
            action(ReplenishRule)
            {
                Caption = 'Replenish now';
                ToolTip = 'Specifies the action that measures this bin and raises the work to top it up, if it has run low.';
                Image = Refresh;

                trigger OnAction()
                begin
                    ApplyReplenish();
                end;
            }
        }
        area(Navigation)
        {
            action(RuleWork)
            {
                Caption = 'Replenishment work';
                ToolTip = 'Specifies the action that shows the warehouse tasks raised for this bin.';
                Image = List;
                RunObject = page "WHA Warehouse Tasks";
                RunPageLink = "Location Code" = field("Location Code"), "To Bin Code" = field("Bin Code"), "Item No." = field("Item No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ReplenishRuleRef; ReplenishRule)
                {
                }
                actionref(RuleWorkRef; RuleWork)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        MeasureBin();
    end;

    var
        MethodDescription: Text;
        InTheBinNow: Decimal;
        WouldAskFor: Decimal;
        NothingNeededMsg: Label 'The bin has enough. No work was raised.';
        RaisedMsg: Label 'Replenishment work %1 was raised.', Comment = '%1 = the number of the warehouse task that was created';
        AlreadyOutstandingMsg: Label 'The bin has run low, but replenishment work for it is already outstanding.';

    local procedure MeasureBin()
    var
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        MethodDescription := ReplenishmentMgt.DescribeMethod(Rec);
        InTheBinNow := ReplenishmentMgt.Measure(Rec);
        WouldAskFor := ReplenishmentMgt.Shortfall(Rec);
    end;

    local procedure ApplyReplenish()
    var
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
        TaskNo: Code[20];
        Needed: Decimal;
    begin
        Needed := ReplenishmentMgt.Shortfall(Rec);
        TaskNo := ReplenishmentMgt.RunRule(Rec);

        if TaskNo <> '' then
            Message(RaisedMsg, TaskNo)
        else
            if Needed > 0 then
                Message(AlreadyOutstandingMsg)
            else
                Message(NothingNeededMsg);

        CurrPage.Update(false);
    end;
}
