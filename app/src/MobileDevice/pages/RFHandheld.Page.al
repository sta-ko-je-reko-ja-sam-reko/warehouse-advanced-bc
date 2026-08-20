namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.DirectedWork;

page 50103 "WHA RF Handheld"
{
    PageType = Card;
    ApplicationArea = WHAMobileDevice;
    UsageCategory = Tasks;
    SourceTable = "WHA Warehouse Task";
    Caption = 'Handheld';
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Editable = false;
    AdditionalSearchTerms = 'RF, scanner, handheld, terminal, picking';

    layout
    {
        area(Content)
        {
            usercontrol(Terminal; "WHA RF Terminal")
            {
                ApplicationArea = WHAMobileDevice;

                trigger Ready()
                begin
                    TerminalReady := true;
                    Refresh();
                end;

                trigger Scanned(ScannedValue: Text)
                begin
                    ScanInput := ScannedValue;
                    ApplyScan();
                end;

                trigger NextTaskRequested()
                begin
                    TakeNextTask();
                end;

                trigger ConfirmRequested()
                begin
                    ApplyConfirm();
                end;

                trigger ShortPickRequested()
                begin
                    ApplyStartShortPick();
                end;

                trigger HandBackRequested()
                begin
                    ApplyHandBack();
                end;
            }
            group(Instruction)
            {
                Caption = 'What to do';
                Visible = ClassicVisible;

                field(InstructionText; InstructionText)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies the one thing to do next.';
                    Editable = false;
                    MultiLine = true;
                    Style = Strong;
                }
                field(ScanInput; ScanInput)
                {
                    Caption = 'Scan';
                    ToolTip = 'Specifies where to scan. Point the scanner and pull the trigger, or type the code and press Enter.';
                    Editable = true;

                    trigger OnValidate()
                    begin
                        ApplyScan();
                    end;
                }
            }
            group(Device)
            {
                Caption = 'Handheld';
                Visible = ClassicVisible;

                field(DeviceCode; DeviceCode)
                {
                    Caption = 'Device code';
                    ToolTip = 'Specifies the handheld you are working on. It decides which part of the warehouse you are offered work in.';
                    TableRelation = "WHA RF Device".Code;
                    Editable = true;

                    trigger OnValidate()
                    begin
                        SignIn();
                    end;
                }
                field(DeviceLocation; RFDevice."Default Location Code")
                {
                    Caption = 'Location';
                    ToolTip = 'Specifies the location this handheld works at.';
                    Editable = false;
                }
            }
            group(Short)
            {
                Caption = 'What you found';
                Visible = ShortVisible;

                field(HandledQuantity; HandledQuantity)
                {
                    Caption = 'Quantity found';
                    ToolTip = 'Specifies how many you actually found. Enter zero if there were none at all.';
                    DecimalPlaces = 0 : 5;
                    MinValue = 0;
                    Editable = true;
                }
                field(ShortReason; ShortReason)
                {
                    Caption = 'Why';
                    ToolTip = 'Specifies why the rest is missing, so the office knows what to do about it.';
                    Editable = true;
                }
            }
            group(Job)
            {
                Caption = 'Your job';
                Visible = HasJob and ClassicVisible;

                field("No."; Rec."No.")
                {
                }
                field("Task Type"; Rec."Task Type")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                }
                field("Handling Unit No."; Rec."Handling Unit No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field(Quantity; Rec.Quantity)
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextTask)
            {
                Caption = 'Next task';
                ToolTip = 'Specifies the action that gives you the next job to do.';
                Image = NextRecord;
                Enabled = not HasJob;

                trigger OnAction()
                begin
                    TakeNextTask();
                end;
            }
            action(ConfirmTask)
            {
                Caption = 'Confirm';
                ToolTip = 'Specifies the action that finishes the job you are holding.';
                Image = Approve;
                Enabled = HasJob;

                trigger OnAction()
                begin
                    ApplyConfirm();
                end;
            }
            action(ShortPickTask)
            {
                Caption = 'Report short';
                ToolTip = 'Specifies the action for when there is less on the shelf than the job asks for.';
                Image = Warning;
                Enabled = HasJob and not ShortVisible;

                trigger OnAction()
                begin
                    ApplyStartShortPick();
                end;
            }
            action(ConfirmShortTask)
            {
                Caption = 'Confirm short';
                ToolTip = 'Specifies the action that finishes the job with what you actually found.';
                Image = ApprovalSetup;
                Enabled = ShortVisible;

                trigger OnAction()
                begin
                    ApplyShortPick();
                end;
            }
            action(SimulatorView)
            {
                Caption = 'Simulator';
                ToolTip = 'Specifies the action that draws the terminal as a handheld and offers the labels within reach as buttons, so the screen can be tried out from a desk. It changes nothing about how the work is done.';
                Image = Setup;

                trigger OnAction()
                begin
                    SimulatorMode := not SimulatorMode;
                    Refresh();
                end;
            }
            action(ClassicView)
            {
                Caption = 'Classic fields';
                ToolTip = 'Specifies the action that shows the plain Business Central fields underneath the terminal. Use it if the terminal does not appear, or to see a field the terminal does not show.';
                Image = ViewDetails;

                trigger OnAction()
                begin
                    ClassicVisible := not ClassicVisible;
                    CurrPage.Update(false);
                end;
            }
            action(HandBackTask)
            {
                Caption = 'Hand back';
                ToolTip = 'Specifies the action that returns the job to the queue for somebody else.';
                Image = Undo;
                Enabled = HasJob;

                trigger OnAction()
                begin
                    ApplyHandBack();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(NextTaskRef; NextTask)
                {
                }
                actionref(ConfirmTaskRef; ConfirmTask)
                {
                }
                actionref(ShortPickTaskRef; ShortPickTask)
                {
                }
                actionref(ConfirmShortTaskRef; ConfirmShortTask)
                {
                }
                actionref(HandBackTaskRef; HandBackTask)
                {
                }
                actionref(SimulatorViewRef; SimulatorView)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentStep := CurrentStep::WHASignIn;
        Refresh();
    end;

    var
        RFDevice: Record "WHA RF Device";
        CurrentStep: Enum "WHA RF Step";
        ShortReason: Enum "WHA Whse. Short Reason";
        DeviceCode: Code[20];
        ScanInput: Text;
        InstructionText: Text;
        HandledQuantity: Decimal;
        HasJob: Boolean;
        ShortVisible: Boolean;
        ClassicVisible: Boolean;
        SimulatorMode: Boolean;
        TerminalReady: Boolean;

    local procedure SignIn()
    begin
        Flow().SignIn(DeviceCode, RFDevice);
        CurrentStep := CurrentStep::WHAGetWork;
        Refresh();
    end;

    local procedure TakeNextTask()
    var
        NoWorkMsg: Label 'There is no work waiting for you at the moment.';
    begin
        if not Flow().NextTask(RFDevice, Rec) then begin
            Message(NoWorkMsg);
            exit;
        end;

        CurrentStep := Flow().FirstStep(Rec);
        Refresh();
    end;

    local procedure ApplyScan()
    var
        Scanned: Text;
    begin
        if ScanInput = '' then
            exit;

        Scanned := ScanInput;
        ScanInput := '';

        if CurrentStep = CurrentStep::WHASignIn then begin
            DeviceCode := CopyStr(Scanned, 1, MaxStrLen(DeviceCode));
            SignIn();
            exit;
        end;

        CurrentStep := Flow().Scan(Rec, CurrentStep, Scanned);
        Refresh();
    end;

    local procedure ApplyStartShortPick()
    begin
        CurrentStep := Flow().StartShortPick(Rec, CurrentStep);
        HandledQuantity := 0;
        Clear(ShortReason);
        Refresh();
    end;

    local procedure ApplyShortPick()
    begin
        CurrentStep := Flow().ShortPick(Rec, HandledQuantity, ShortReason);
        ClearJob();
    end;

    local procedure ApplyConfirm()
    begin
        CurrentStep := Flow().Confirm(Rec, CurrentStep);
        ClearJob();
    end;

    local procedure ApplyHandBack()
    begin
        CurrentStep := Flow().HandBack(Rec);
        ClearJob();
    end;

    local procedure ClearJob()
    begin
        Rec.Init();
        HandledQuantity := 0;
        Clear(ShortReason);
        Refresh();
    end;

    local procedure Refresh()
    var
        TerminalState: Codeunit "WHA RF Terminal State";
    begin
        HasJob := Rec."No." <> '';
        ShortVisible := CurrentStep = CurrentStep::WHAShortPick;
        InstructionText := Flow().Instruction(Rec, CurrentStep);

        if TerminalReady then
            CurrPage.Terminal.Render(TerminalState.Build(Rec, RFDevice, CurrentStep, InstructionText, SimulatorMode));

        CurrPage.Update(false);
    end;

    local procedure Flow(): Interface "WHA IRFFlow"
    var
        Setup: Record "WHA RF Setup";
        DefaultFlow: Enum "WHA RF Flow";
    begin
        Setup.SetLoadFields(Flow);
        if not Setup.Get() then
            exit(DefaultFlow);
        exit(Setup.Flow);
    end;
}
