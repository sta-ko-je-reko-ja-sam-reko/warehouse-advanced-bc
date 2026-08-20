namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.HandlingUnit;

codeunit 50104 "WHA RF Terminal State"
{
    Access = Public;

    var
        SignInKeyLbl: Label 'Sign in';
        NextTaskKeyLbl: Label 'Next task';
        ConfirmKeyLbl: Label 'Confirm';
        ConfirmShortKeyLbl: Label 'Confirm short';
        NeighbourTok: Label '%1%2', Locked = true;

    /// <summary>
    /// Builds the document the terminal draws itself from. Every decision is already made by the time it
    /// gets here — this states what is true, and the add-in shows it. Keeping the shape in AL rather than
    /// in the script is what makes it testable at all: nothing in this app can run JavaScript, and a
    /// terminal whose behaviour lived in the script would be a second implementation nobody could check.
    /// </summary>
    /// <param name="WarehouseTask">The job the operator is holding, or a blank record when they are not.</param>
    /// <param name="RFDevice">The handheld they signed in on.</param>
    /// <param name="CurrentStep">The step they are on.</param>
    /// <param name="InstructionText">The one line they read, already worked out by the flow.</param>
    /// <param name="SimulatorMode">Whether to include the things only a desk needs: a device frame, and labels to tap.</param>
    /// <returns>The state document, as JSON.</returns>
    procedure Build(var WarehouseTask: Record "WHA Warehouse Task"; var RFDevice: Record "WHA RF Device"; CurrentStep: Enum "WHA RF Step"; InstructionText: Text; SimulatorMode: Boolean): Text
    var
        StateObject: JsonObject;
        StateText: Text;
        HasJob: Boolean;
    begin
        HasJob := WarehouseTask."No." <> '';

        StateObject.Add('step', Format(CurrentStep, 0, 9));
        StateObject.Add('stepLabel', Format(CurrentStep));
        StateObject.Add('instruction', InstructionText);
        StateObject.Add('device', DeviceObject(RFDevice));
        StateObject.Add('job', JobObject(WarehouseTask, HasJob));
        StateObject.Add('wantsScan', WantsScan(CurrentStep));
        StateObject.Add('wantsShortForm', CurrentStep = CurrentStep::WHAShortPick);
        StateObject.Add('target', TargetOf(WarehouseTask, CurrentStep));
        StateObject.Add('primaryKey', PrimaryKeyCaption(CurrentStep));
        StateObject.Add('primaryEnabled', CurrentStep <> CurrentStep::WHAShortPick);
        StateObject.Add('shortEnabled', HasJob and (CurrentStep <> CurrentStep::WHAShortPick));
        StateObject.Add('handBackEnabled', HasJob);
        StateObject.Add('simulator', SimulatorMode);
        StateObject.Add('labels', LabelArray(WarehouseTask, CurrentStep, SimulatorMode));

        StateObject.WriteTo(StateText);
        exit(StateText);
    end;

    /// <summary>
    /// The labels an operator could reach for at this step. Only ever sent in simulator mode: on a real
    /// handheld the labels are on the racking, and a list of them on the screen would be a way of
    /// finishing a job without walking anywhere.
    /// </summary>
    /// <param name="WarehouseTask">The job being worked.</param>
    /// <param name="CurrentStep">The step the operator is on.</param>
    /// <param name="SimulatorMode">Whether labels are wanted at all.</param>
    /// <returns>The codes to offer, wanted one included but deliberately not first.</returns>
    procedure LabelArray(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"; SimulatorMode: Boolean): JsonArray
    var
        HandlingUnit: Record "WHA Handling Unit";
        Labels: List of [Text];
        Wanted: Text;
        LabelArrayValue: JsonArray;
        LabelValue: Text;
    begin
        if not SimulatorMode then
            exit(LabelArrayValue);

        case CurrentStep of
            CurrentStep::WHAScanFrom:
                begin
                    Wanted := WarehouseTask."From Bin Code";
                    AddLabel(Labels, Neighbour(WarehouseTask."From Bin Code"));
                    AddLabel(Labels, WarehouseTask."Item No.");
                    AddLabel(Labels, WarehouseTask."Handling Unit No.");
                end;
            CurrentStep::WHAScanUnit:
                begin
                    Wanted := WarehouseTask."Handling Unit No.";
                    AddLabel(Labels, WarehouseTask."Item No.");
                    AddLabel(Labels, WarehouseTask."From Bin Code");
                    HandlingUnit.SetLoadFields(SSCC);
                    if HandlingUnit.Get(WarehouseTask."Handling Unit No.") then
                        AddLabel(Labels, HandlingUnit.SSCC);
                end;
            CurrentStep::WHAScanTo:
                begin
                    Wanted := WarehouseTask."To Bin Code";
                    AddLabel(Labels, Neighbour(WarehouseTask."To Bin Code"));
                    AddLabel(Labels, WarehouseTask."Item No.");
                end;
        end;

        if Wanted <> '' then
            InsertWanted(Labels, Wanted);

        foreach LabelValue in Labels do
            LabelArrayValue.Add(LabelValue);

        exit(LabelArrayValue);
    end;

    local procedure DeviceObject(var RFDevice: Record "WHA RF Device"): JsonObject
    var
        DeviceObjectValue: JsonObject;
    begin
        DeviceObjectValue.Add('code', RFDevice.Code);
        DeviceObjectValue.Add('location', RFDevice."Default Location Code");
        exit(DeviceObjectValue);
    end;

    local procedure JobObject(var WarehouseTask: Record "WHA Warehouse Task"; HasJob: Boolean): JsonObject
    var
        JobObjectValue: JsonObject;
    begin
        JobObjectValue.Add('hasJob', HasJob);
        JobObjectValue.Add('number', WarehouseTask."No.");
        JobObjectValue.Add('type', Format(WarehouseTask."Task Type"));
        JobObjectValue.Add('description', WarehouseTask.Description);
        JobObjectValue.Add('fromBin', WarehouseTask."From Bin Code");
        JobObjectValue.Add('toBin', WarehouseTask."To Bin Code");
        JobObjectValue.Add('handlingUnit', WarehouseTask."Handling Unit No.");
        JobObjectValue.Add('item', WarehouseTask."Item No.");
        JobObjectValue.Add('quantity', WarehouseTask.Quantity);
        JobObjectValue.Add('unitOfMeasure', WarehouseTask."Unit of Measure Code");
        exit(JobObjectValue);
    end;

    local procedure WantsScan(CurrentStep: Enum "WHA RF Step"): Boolean
    begin
        exit(CurrentStep in [CurrentStep::WHASignIn, CurrentStep::WHAScanFrom, CurrentStep::WHAScanUnit, CurrentStep::WHAScanTo]);
    end;

    local procedure TargetOf(var WarehouseTask: Record "WHA Warehouse Task"; CurrentStep: Enum "WHA RF Step"): Text
    begin
        case CurrentStep of
            CurrentStep::WHAScanFrom:
                exit(WarehouseTask."From Bin Code");
            CurrentStep::WHAScanUnit:
                exit(WarehouseTask."Handling Unit No.");
            CurrentStep::WHAScanTo:
                exit(WarehouseTask."To Bin Code");
        end;

        exit('');
    end;

    local procedure PrimaryKeyCaption(CurrentStep: Enum "WHA RF Step"): Text
    begin
        case CurrentStep of
            CurrentStep::WHASignIn:
                exit(SignInKeyLbl);
            CurrentStep::WHAGetWork:
                exit(NextTaskKeyLbl);
            CurrentStep::WHAShortPick:
                exit(ConfirmShortKeyLbl);
        end;

        exit(ConfirmKeyLbl);
    end;

    local procedure AddLabel(var Labels: List of [Text]; Value: Text)
    begin
        if Value = '' then
            exit;
        if Labels.Contains(Value) then
            exit;

        Labels.Add(Value);
    end;

    local procedure InsertWanted(var Labels: List of [Text]; Wanted: Text)
    var
        Position: Integer;
    begin
        if Labels.Contains(Wanted) then
            exit;

        Position := 2;
        if Labels.Count() < 1 then
            Position := 1;

        Labels.Insert(Position, Wanted);
    end;

    local procedure Neighbour(BinCode: Code[20]): Text
    var
        Digits: Text;
        Head: Text;
        Position: Integer;
        Number: Integer;
    begin
        if BinCode = '' then
            exit('');

        Position := StrLen(BinCode);
        while (Position > 0) and (BinCode[Position] in ['0' .. '9']) do begin
            Digits := Format(BinCode[Position]) + Digits;
            Position -= 1;
        end;

        if Digits = '' then
            exit('');

        Head := CopyStr(BinCode, 1, Position);
        Evaluate(Number, Digits);
        exit(StrSubstNo(NeighbourTok, Head, PadDigits(Number + 1, StrLen(Digits))));
    end;

    local procedure PadDigits(Value: Integer; Width: Integer): Text
    var
        Padded: Text;
    begin
        Padded := Format(Value);
        while StrLen(Padded) < Width do
            Padded := '0' + Padded;

        exit(Padded);
    end;
}
