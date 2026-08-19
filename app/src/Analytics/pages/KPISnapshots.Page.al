namespace WarehouseAdvanced.Analytics;

page 50702 "WHA KPI Snapshots"
{
    PageType = List;
    ApplicationArea = WHAAnalytics;
    UsageCategory = Lists;
    SourceTable = "WHA KPI Snapshot";
    Caption = 'KPI snapshots';
    Editable = false;
    InsertAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Snapshots)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field(Measure; Rec.Measure)
                {
                }
                field(Value; Rec.Value)
                {
                    StyleExpr = MovementStyle;
                }
                field("Measured In"; Rec."Measured In")
                {
                }
                field("From Date"; Rec."From Date")
                {
                }
                field("To Date"; Rec."To Date")
                {
                }
                field("Captured At"; Rec."Captured At")
                {
                }
                field("Captured By User ID"; Rec."Captured By User ID")
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenKPIs)
            {
                Caption = 'Warehouse KPIs';
                ToolTip = 'Specifies the action that opens the figures worked out on the spot, where a new set can be kept.';
                Image = Statistics;
                RunObject = page "WHA Warehouse KPIs";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenKPIsRef; OpenKPIs)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetMovementStyle();
    end;

    var
        MovementStyle: Text;

    local procedure SetMovementStyle()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
    begin
        case KpiMgt.ComparedWithPrevious(Rec) of
            1:
                MovementStyle := 'Favorable';
            -1:
                MovementStyle := 'Unfavorable';
            else
                MovementStyle := 'Standard';
        end;
    end;
}
