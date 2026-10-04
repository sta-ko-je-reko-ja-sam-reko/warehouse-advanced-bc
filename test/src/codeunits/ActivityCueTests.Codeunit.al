namespace WarehouseAdvanced.Test;

using System.TestLibraries.Utilities;
using WarehouseAdvanced.Core;
using WarehouseAdvanced.Counting;
using WarehouseAdvanced.DirectedWork;
using WarehouseAdvanced.DockYard;
using WarehouseAdvanced.Integration;
using WarehouseAdvanced.Packing;
using WarehouseAdvanced.Replenishment;
using WarehouseAdvanced.Slotting;
using WarehouseAdvanced.WaveManagement;

codeunit 59022 "WHA Activity Cue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure EveryTileIsEmptyWhenEveryFeatureIsOff()
    var
        Results: Dictionary of [Text, Text];
        FeatureSetup: Interface "WHA IFeatureSetup";
        ActivityCues: Interface "WHA IActivityCues";
        States: List of [Boolean];
        Ordinal: Integer;
    begin
        // [SCENARIO] A feature that is switched off has nothing for anybody to act on, so the role centre
        // shows no count for it rather than counting work nobody can see.
        // [GIVEN] Every feature switched off
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            FeatureSetup := Enum::"WHA Feature".FromInteger(Ordinal);
            States.Add(FeatureSetup.IsEnabled());
            FeatureSetup.ApplyChoices(false, false, false);
        end;

        // [WHEN] Every provider adds its counts
        foreach Ordinal in Enum::"WHA Activity Provider".Ordinals() do begin
            ActivityCues := Enum::"WHA Activity Provider".FromInteger(Ordinal);
            ActivityCues.AddCounts(Results);
        end;

        // [THEN] No tile has a count
        Assert.AreEqual(0, Results.Count(), 'With every feature off no provider should add a count.');
        RestoreStates(States);
    end;

    [Test]
    procedure OnlyMessagesThatArrivedAreWaiting()
    var
        TempActivitiesCue: Record "WHA Activities Cue";
        IntegrationSetup: Record "WHA Integration Setup";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        ActivityCues: Interface "WHA IActivityCues";
        MessageType: Enum "WHA Int. Message Type";
        WaitingBefore: Integer;
        FailedBefore: Integer;
    begin
        // [SCENARIO] Regression. The tile says how many messages have arrived and are not worked through.
        // An outbound message waiting for the partner to collect it is not something anybody here can work
        // through, and used to be counted with them.
        // [GIVEN] Integration on, not applying messages on arrival
        SwitchOn(Enum::"WHA Feature"::WHAIntegration);
        IntegrationSetup.Get();
        IntegrationSetup."Auto Process Inbound" := false;
        IntegrationSetup.Modify(false);
        ActivityCues := Enum::"WHA Activity Provider"::WHAIntegration;
        WaitingBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Messages Waiting"));
        FailedBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Messages Failed"));

        // [WHEN] One message arrives, one is written for the partner, and one fails
        MessageMgt.CreateInbound(MessageType::WHAWarehouseTaskRequest, 'CUE-IN-1', '', '{}');
        MessageMgt.CreateOutbound(MessageType::WHAStockPosition, 'CUE-OUT-1', '{}', TempActivitiesCue.RecordId());
        FailOneMessage('CUE-FAIL-1');

        // [THEN] One more is waiting and one more has failed
        Assert.AreEqual(WaitingBefore + 1, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Messages Waiting")), 'Only the message that arrived is waiting.');
        Assert.AreEqual(FailedBefore + 1, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Messages Failed")), 'The message that failed is counted.');
    end;

    [Test]
    procedure WorkInProgressAndOverdueWorkAreCounted()
    var
        TempActivitiesCue: Record "WHA Activities Cue";
        ActivityCues: Interface "WHA IActivityCues";
        InProgressBefore: Integer;
        OverdueBefore: Integer;
    begin
        // [GIVEN] Directed work on
        SwitchOn(Enum::"WHA Feature"::WHADirectedWork);
        ActivityCues := Enum::"WHA Activity Provider"::WHADirectedWork;
        InProgressBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Tasks In Progress"));
        OverdueBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Tasks Overdue"));

        // [WHEN] One job is being worked, one waiting job is past its date, and one finished job was past its date
        InsertTask('CUE-T-IP', Enum::"WHA Warehouse Task Status"::WHAInProgress, 0D);
        InsertTask('CUE-T-LATE', Enum::"WHA Warehouse Task Status"::WHAReleased, WorkDate() - 1);
        InsertTask('CUE-T-DONE', Enum::"WHA Warehouse Task Status"::WHACompleted, WorkDate() - 1);

        // [THEN] One more is in progress and one more is overdue; finished work is not overdue
        Assert.AreEqual(InProgressBefore + 1, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Tasks In Progress")), 'The job being worked is counted.');
        Assert.AreEqual(OverdueBefore + 1, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Tasks Overdue")), 'Only the unfinished late job is overdue.');
    end;

    [Test]
    procedure VehiclesOnSiteAndWaitingAreCounted()
    var
        TempActivitiesCue: Record "WHA Activities Cue";
        ActivityCues: Interface "WHA IActivityCues";
        OnSiteBefore: Integer;
        WaitingBefore: Integer;
    begin
        // [GIVEN] The yard on
        SwitchOn(Enum::"WHA Feature"::WHADockYard);
        ActivityCues := Enum::"WHA Activity Provider"::WHADockYard;
        OnSiteBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Vehicles On Site"));
        WaitingBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Vehicles Waiting"));

        // [WHEN] One vehicle is parked waiting and another stands at a door
        InsertAppointment('CUE-DA-WAIT', Enum::"WHA Appointment Status"::WHAArrived);
        InsertAppointment('CUE-DA-DOOR', Enum::"WHA Appointment Status"::WHAAtDoor);

        // [THEN] Both are on site, and only the parked one is waiting
        Assert.AreEqual(OnSiteBefore + 2, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Vehicles On Site")), 'Both vehicles are on site.');
        Assert.AreEqual(WaitingBefore + 1, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Vehicles Waiting")), 'Only the parked vehicle is waiting for a door.');
    end;

    [Test]
    procedure WavesBeingBuiltAndOnTheFloorAreCounted()
    var
        TempActivitiesCue: Record "WHA Activities Cue";
        ActivityCues: Interface "WHA IActivityCues";
        OpenBefore: Integer;
        OnFloorBefore: Integer;
    begin
        // [GIVEN] Wave management on
        SwitchOn(Enum::"WHA Feature"::WHAWaveManagement);
        ActivityCues := Enum::"WHA Activity Provider"::WHAWaveManagement;
        OpenBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Waves Open"));
        OnFloorBefore := CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Waves On Floor"));

        // [WHEN] One wave is being built and one has been released
        InsertWave('CUE-WV-OPEN', Enum::"WHA Wave Status"::WHAOpen);
        InsertWave('CUE-WV-REL', Enum::"WHA Wave Status"::WHAReleased);

        // [THEN] Each is counted on its own tile
        Assert.AreEqual(OpenBefore + 1, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Waves Open")), 'The wave being built is counted.');
        Assert.AreEqual(OnFloorBefore + 1, CueValue(ActivityCues, TempActivitiesCue.FieldNo("WHA Waves On Floor")), 'The released wave is counted.');
    end;

    [Test]
    procedure CartonsRulesProposalsAndSheetsAreCounted()
    var
        CountSheet: Record "WHA Count Sheet";
        PackSession: Record "WHA Pack Session";
        ReplenishmentRule: Record "WHA Replenishment Rule";
        SlottingProposal: Record "WHA Slotting Proposal";
        TempActivitiesCue: Record "WHA Activities Cue";
        CountCues: Interface "WHA IActivityCues";
        PackCues: Interface "WHA IActivityCues";
        ReplCues: Interface "WHA IActivityCues";
        SlotCues: Interface "WHA IActivityCues";
        CartonsBefore: Integer;
        RulesBefore: Integer;
        ProposalsBefore: Integer;
        SheetsBefore: Integer;
    begin
        // [GIVEN] Packing, replenishment, slotting and counting on
        SwitchOn(Enum::"WHA Feature"::WHAPacking);
        SwitchOn(Enum::"WHA Feature"::WHAReplenishment);
        SwitchOn(Enum::"WHA Feature"::WHASlotting);
        SwitchOn(Enum::"WHA Feature"::WHACounting);
        PackCues := Enum::"WHA Activity Provider"::WHAPacking;
        ReplCues := Enum::"WHA Activity Provider"::WHAReplenishment;
        SlotCues := Enum::"WHA Activity Provider"::WHASlotting;
        CountCues := Enum::"WHA Activity Provider"::WHACounting;
        CartonsBefore := CueValue(PackCues, TempActivitiesCue.FieldNo("WHA Cartons Being Packed"));
        RulesBefore := CueValue(ReplCues, TempActivitiesCue.FieldNo("WHA Repl. Rules Blocked"));
        ProposalsBefore := CueValue(SlotCues, TempActivitiesCue.FieldNo("WHA Slotting Proposals Open"));
        SheetsBefore := CueValue(CountCues, TempActivitiesCue.FieldNo("WHA Count Sheets Out"));

        // [WHEN] A carton is being packed, a rule is blocked, a proposal is open and a sheet is out for counting
        PackSession.Init();
        PackSession.Status := PackSession.Status::WHAPacking;
        PackSession.Insert(false);
        ReplenishmentRule.Init();
        ReplenishmentRule."Location Code" := 'WHACUE';
        ReplenishmentRule."Item No." := 'WHA-CUE-ITEM';
        ReplenishmentRule."Bin Code" := 'CUE-01';
        ReplenishmentRule.Blocked := true;
        ReplenishmentRule.Insert(false);
        SlottingProposal.Init();
        SlottingProposal."Location Code" := 'WHACUE';
        SlottingProposal."Item No." := 'WHA-CUE-ITEM';
        SlottingProposal.Status := SlottingProposal.Status::WHAOpen;
        SlottingProposal.Insert(false);
        CountSheet.Init();
        CountSheet."No." := 'CUE-CNT-1';
        CountSheet.Status := CountSheet.Status::WHACounting;
        CountSheet.Insert(false);

        // [THEN] Each tile counts one more
        Assert.AreEqual(CartonsBefore + 1, CueValue(PackCues, TempActivitiesCue.FieldNo("WHA Cartons Being Packed")), 'The carton being packed is counted.');
        Assert.AreEqual(RulesBefore + 1, CueValue(ReplCues, TempActivitiesCue.FieldNo("WHA Repl. Rules Blocked")), 'The blocked rule is counted.');
        Assert.AreEqual(ProposalsBefore + 1, CueValue(SlotCues, TempActivitiesCue.FieldNo("WHA Slotting Proposals Open")), 'The open proposal is counted.');
        Assert.AreEqual(SheetsBefore + 1, CueValue(CountCues, TempActivitiesCue.FieldNo("WHA Count Sheets Out")), 'The sheet out for counting is counted.');
    end;

    local procedure CueValue(ActivityCues: Interface "WHA IActivityCues"; CueFieldNo: Integer): Integer
    var
        Results: Dictionary of [Text, Text];
        CountText: Text;
        CountValue: Integer;
    begin
        ActivityCues.AddCounts(Results);
        if not Results.Get(Format(CueFieldNo), CountText) then
            Error('The provider did not add a count for field %1.', CueFieldNo);
        Evaluate(CountValue, CountText);
        exit(CountValue);
    end;

    local procedure SwitchOn(Feature: Enum "WHA Feature")
    var
        FeatureSetup: Interface "WHA IFeatureSetup";
    begin
        FeatureSetup := Feature;
        FeatureSetup.ApplyChoices(true, false, false);
    end;

    local procedure RestoreStates(States: List of [Boolean])
    var
        FeatureSetup: Interface "WHA IFeatureSetup";
        Ordinal: Integer;
        Index: Integer;
    begin
        foreach Ordinal in Enum::"WHA Feature".Ordinals() do begin
            Index += 1;
            FeatureSetup := Enum::"WHA Feature".FromInteger(Ordinal);
            FeatureSetup.ApplyChoices(States.Get(Index), false, false);
        end;
    end;

    local procedure FailOneMessage(ExternalId: Code[50])
    var
        IntegrationMessage: Record "WHA Integration Message";
        MessageMgt: Codeunit "WHA Int. Message Mgt.";
        MessageType: Enum "WHA Int. Message Type";
    begin
        IntegrationMessage.Get(MessageMgt.CreateInbound(MessageType::WHAUnknown, ExternalId, '', '{}'));
        MessageMgt.Process(IntegrationMessage);
    end;

    local procedure InsertTask(TaskNo: Code[20]; Status: Enum "WHA Warehouse Task Status"; DueDate: Date)
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask.Status := Status;
        WarehouseTask."Due Date" := DueDate;
        WarehouseTask.Insert(false);
    end;

    local procedure InsertAppointment(AppointmentNo: Code[20]; Status: Enum "WHA Appointment Status")
    var
        DockAppointment: Record "WHA Dock Appointment";
    begin
        DockAppointment.Init();
        DockAppointment."No." := AppointmentNo;
        DockAppointment.Status := Status;
        DockAppointment.Insert(false);
    end;

    local procedure InsertWave(WaveNo: Code[20]; Status: Enum "WHA Wave Status")
    var
        Wave: Record "WHA Wave";
    begin
        Wave.Init();
        Wave."No." := WaveNo;
        Wave.Status := Status;
        Wave.Insert(false);
    end;
}
