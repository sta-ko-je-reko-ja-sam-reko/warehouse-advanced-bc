namespace WarehouseAdvanced.Analytics;

using Microsoft.Inventory.Location;

page 50701 "WHA Warehouse KPIs"
{
    PageType = Worksheet;
    ApplicationArea = WHAAnalytics;
    UsageCategory = ReportsAndAnalysis;
    SourceTable = "WHA KPI Snapshot";
    SourceTableTemporary = true;
    Caption = 'Warehouse KPIs';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(Options)
            {
                Caption = 'What to measure';

                field(LocationFilter; LocationFilter)
                {
                    Editable = true;
                    Caption = 'Location';
                    ToolTip = 'Specifies the site to measure. Leave it blank to measure the whole company as one.';
                    TableRelation = Location;

                    trigger OnValidate()
                    begin
                        RefreshFigures();
                    end;
                }
                field(FromDate; FromDate)
                {
                    Editable = true;
                    Caption = 'From date';
                    ToolTip = 'Specifies the first day to count. Leave it blank to use the period from the analytics setup.';

                    trigger OnValidate()
                    begin
                        RefreshFigures();
                    end;
                }
                field(ToDate; ToDate)
                {
                    Editable = true;
                    Caption = 'To date';
                    ToolTip = 'Specifies the last day to count. Leave it blank to count up to today.';

                    trigger OnValidate()
                    begin
                        RefreshFigures();
                    end;
                }
            }
            repeater(Figures)
            {
                field(Measure; Rec.Measure)
                {
                }
                field(Value; Rec.Value)
                {
                    StyleExpr = ValueStyle;
                }
                field("Measured In"; Rec."Measured In")
                {
                }
                field(MeasureDescription; MeasureDescription)
                {
                    Caption = 'What it counts';
                    ToolTip = 'Specifies what the measure counts and what it deliberately leaves out.';
                    MultiLine = true;
                }
                field("From Date"; Rec."From Date")
                {
                }
                field("To Date"; Rec."To Date")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshNow)
            {
                Caption = 'Work them out again';
                ToolTip = 'Specifies the action that works every figure out again from what has been recorded since.';
                Image = Refresh;

                trigger OnAction()
                begin
                    RefreshFigures();
                end;
            }
            action(CaptureNow)
            {
                Caption = 'Keep these figures';
                ToolTip = 'Specifies the action that keeps this set of figures, so that the period can be compared with another one later.';
                Image = Save;

                trigger OnAction()
                begin
                    ApplyCapture();
                end;
            }
        }
        area(Navigation)
        {
            action(OpenSnapshots)
            {
                Caption = 'KPI snapshots';
                ToolTip = 'Specifies the action that opens the figures that have been kept.';
                Image = History;
                RunObject = page "WHA KPI Snapshots";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RefreshNowRef; RefreshNow)
                {
                }
                actionref(CaptureNowRef; CaptureNow)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        RefreshFigures();
    end;

    trigger OnAfterGetRecord()
    begin
        DescribeMeasure();
        SetValueStyle();
    end;

    var
        LocationFilter: Code[10];
        FromDate: Date;
        ToDate: Date;
        MeasureDescription: Text;
        ValueStyle: Text;
        CapturedMsg: Label '%1 figure(s) were kept for %2 to %3.', Comment = '%1 = how many figures were kept, %2 = the first day counted, %3 = the last day counted';

    local procedure RefreshFigures()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
    begin
        KpiMgt.Refresh(Rec, LocationFilter, FromDate, ToDate);
        CurrPage.Update(false);
    end;

    local procedure ApplyCapture()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
        Kept: Integer;
    begin
        Kept := KpiMgt.Capture(LocationFilter, FromDate, ToDate);
        Message(CapturedMsg, Kept, FromDate, ToDate);
    end;

    local procedure DescribeMeasure()
    var
        KpiMgt: Codeunit "WHA KPI Mgt.";
    begin
        MeasureDescription := KpiMgt.DescribeMeasure(Rec.Measure);
    end;

    local procedure SetValueStyle()
    begin
        if Rec.Value = 0 then
            ValueStyle := 'Subordinate'
        else
            ValueStyle := 'Strong';
    end;
}
