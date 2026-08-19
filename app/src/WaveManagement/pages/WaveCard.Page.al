namespace WarehouseAdvanced.WaveManagement;

using WarehouseAdvanced.DirectedWork;

page 50152 "WHA Wave Card"
{
    PageType = Card;
    ApplicationArea = WHAWaveManagement;
    UsageCategory = None;
    SourceTable = "WHA Wave";
    Caption = 'Wave';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field(Status; Rec.Status)
                {
                }
            }
            group(Building)
            {
                Caption = 'Building';

                field(Strategy; Rec.Strategy)
                {
                }
                field(StrategyDescription; StrategyDescription)
                {
                    Caption = 'What it gathers';
                    ToolTip = 'Specifies what this strategy picks up when the wave is filled.';
                    Editable = false;
                    MultiLine = true;
                }
                field("Max Tasks"; Rec."Max Tasks")
                {
                }
                field("Max Minutes"; Rec."Max Minutes")
                {
                }
                field(EstimatedMinutes; EstimatedMinutes)
                {
                    Caption = 'Minutes of work gathered';
                    ToolTip = 'Specifies how long the work in this wave should take according to the labour standards. It reads zero when nobody has written a standard for this kind of work, which is not the same as a wave with nothing in it.';
                    DecimalPlaces = 0 : 2;
                    Editable = false;
                }
                field(EffortMeasured; EffortMeasured)
                {
                    Caption = 'Measured by a standard';
                    ToolTip = 'Specifies whether any labour standard applied to the work in this wave. When this is off, the minutes above are zero because nothing measured the work, and the wave is limited by its job count alone.';
                    Editable = false;
                }
                field("Template Code"; Rec."Template Code")
                {
                }
            }
            group(Progress)
            {
                Caption = 'Progress';

                field("Task Count"; Rec."Task Count")
                {
                }
                field("Completed Task Count"; Rec."Completed Task Count")
                {
                }
                field("Released At"; Rec."Released At")
                {
                }
                field("Completed At"; Rec."Completed At")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FillWave)
            {
                Caption = 'Fill';
                ToolTip = 'Specifies the action that gathers work into the wave, using its strategy.';
                Image = Refresh;

                trigger OnAction()
                begin
                    ApplyFill();
                end;
            }
            action(ReleaseWave)
            {
                Caption = 'Release';
                ToolTip = 'Specifies the action that sends every job in the wave to the floor at once.';
                Image = ReleaseDoc;

                trigger OnAction()
                begin
                    WaveLogic.Release(Rec);
                end;
            }
            action(CompleteWave)
            {
                Caption = 'Complete';
                ToolTip = 'Specifies the action that closes the wave once all of its work is finished.';
                Image = Approve;

                trigger OnAction()
                begin
                    WaveLogic.Complete(Rec);
                end;
            }
            action(CancelWave)
            {
                Caption = 'Cancel';
                ToolTip = 'Specifies the action that withdraws the wave and cancels any of its work that nobody has started.';
                Image = Cancel;

                trigger OnAction()
                begin
                    WaveLogic.Cancel(Rec);
                end;
            }
        }
        area(Navigation)
        {
            action(WaveTasks)
            {
                Caption = 'Jobs in this wave';
                ToolTip = 'Specifies the action that shows the warehouse tasks gathered into this wave.';
                Image = List;
                RunObject = page "WHA Warehouse Tasks";
                RunPageLink = "Wave No." = field("No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(FillWaveRef; FillWave)
                {
                }
                actionref(ReleaseWaveRef; ReleaseWave)
                {
                }
                actionref(CompleteWaveRef; CompleteWave)
                {
                }
                actionref(WaveTasksRef; WaveTasks)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescribeStrategy();
        MeasureEffort();
    end;

    var
        WaveLogic: Codeunit "WHA Wave Logic";
        StrategyDescription: Text;
        EstimatedMinutes: Decimal;
        EffortMeasured: Boolean;
        FilledMsg: Label '%1 job(s) gathered into the wave.', Comment = '%1 = how many jobs were added';

    local procedure ApplyFill()
    begin
        Message(FilledMsg, WaveLogic.Fill(Rec));
        CurrPage.Update(false);
    end;

    local procedure MeasureEffort()
    begin
        EstimatedMinutes := WaveLogic.EstimateMinutes(Rec, EffortMeasured);
    end;

    local procedure DescribeStrategy()
    var
        WaveStrategy: Interface "WHA IWaveStrategy";
    begin
        WaveStrategy := Rec.Strategy;
        StrategyDescription := WaveStrategy.Describe();
    end;
}
