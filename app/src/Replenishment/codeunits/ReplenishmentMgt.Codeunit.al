namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.DirectedWork;

codeunit 50256 "WHA Replenishment Mgt."
{
    Access = Public;

    var
        BlockedRuleErr: Label 'The replenishment rule for %1 in bin %2 is blocked, so it does not ask for work.', Comment = '%1 = the item number on the rule, %2 = the bin the rule keeps stocked';
        NoMaximumErr: Label 'Give the replenishment rule for %1 in bin %2 a maximum quantity, so a run knows how full to fill the bin.', Comment = '%1 = the item number on the rule, %2 = the bin the rule keeps stocked';
        TaskDescriptionLbl: Label 'Replenish %1 in bin %2', Comment = '%1 = the item number being replenished, %2 = the bin being topped up';

    /// <summary>
    /// Measures every rule at a location and raises replenishment work for each bin that has run below
    /// its minimum. Safe to repeat and safe to schedule: a bin that already has outstanding
    /// replenishment work is left alone, so a run every ten minutes does not send ten people to the same
    /// bin.
    /// </summary>
    /// <param name="LocationCode">The location to look at. Blank looks at every location.</param>
    /// <returns>How many pieces of work were raised.</returns>
    procedure Run(LocationCode: Code[10]): Integer
    var
        ReplenishmentRule: Record "WHA Replenishment Rule";
        Raised: Integer;
    begin
        ReplenishmentRule.SetRange(Blocked, false);
        if LocationCode <> '' then
            ReplenishmentRule.SetRange("Location Code", LocationCode);
        if not ReplenishmentRule.FindSet(true) then
            exit(0);

        repeat
            if RaiseIfNeeded(ReplenishmentRule) <> '' then
                Raised += 1;
        until ReplenishmentRule.Next() = 0;

        exit(Raised);
    end;

    /// <summary>
    /// Measures one rule and raises work for it if the bin has run low. Refuses a blocked rule, because
    /// asking a rule that was deliberately switched off for work should say so rather than quietly do
    /// nothing.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule to act on.</param>
    /// <returns>The number of the work raised, or blank when the bin needs nothing.</returns>
    procedure RunRule(var ReplenishmentRule: Record "WHA Replenishment Rule"): Code[20]
    begin
        if ReplenishmentRule.Blocked then
            Error(BlockedRuleErr, ReplenishmentRule."Item No.", ReplenishmentRule."Bin Code");
        if ReplenishmentRule."Maximum Quantity" = 0 then
            Error(NoMaximumErr, ReplenishmentRule."Item No.", ReplenishmentRule."Bin Code");

        exit(RaiseIfNeeded(ReplenishmentRule));
    end;

    /// <summary>
    /// Answers how much of the rule's item is in its bin right now, using the rule's own method.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule whose bin is being measured.</param>
    /// <returns>The quantity the method believes is in the bin.</returns>
    procedure Measure(var ReplenishmentRule: Record "WHA Replenishment Rule"): Decimal
    var
        ReplMethod: Interface "WHA IReplMethod";
    begin
        ReplMethod := ReplenishmentRule.Method;
        exit(ReplMethod.Measure(ReplenishmentRule));
    end;

    /// <summary>
    /// Answers how much the rule would ask for if it were run now, without raising anything.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule to weigh up.</param>
    /// <returns>The quantity needed to fill the bin to its maximum, or zero when it needs nothing.</returns>
    procedure Shortfall(var ReplenishmentRule: Record "WHA Replenishment Rule"): Decimal
    begin
        exit(ShortfallFrom(ReplenishmentRule, Measure(ReplenishmentRule)));
    end;

    /// <summary>
    /// Describes in one line where the rule's method takes its measurement from.
    /// </summary>
    /// <param name="ReplenishmentRule">The rule to describe.</param>
    /// <returns>A short description in the user's language.</returns>
    procedure DescribeMethod(var ReplenishmentRule: Record "WHA Replenishment Rule"): Text
    var
        ReplMethod: Interface "WHA IReplMethod";
    begin
        ReplMethod := ReplenishmentRule.Method;
        exit(ReplMethod.Describe());
    end;

    local procedure RaiseIfNeeded(var ReplenishmentRule: Record "WHA Replenishment Rule"): Code[20]
    var
        Needed: Decimal;
        TaskNo: Code[20];
    begin
        Needed := ShortfallFrom(ReplenishmentRule, Measure(ReplenishmentRule));

        if (Needed > 0) and not HasOutstandingWork(ReplenishmentRule) then
            TaskNo := RaiseTask(ReplenishmentRule, Needed);

        StampRule(ReplenishmentRule, TaskNo);
        exit(TaskNo);
    end;

    local procedure ShortfallFrom(var ReplenishmentRule: Record "WHA Replenishment Rule"; OnHand: Decimal): Decimal
    begin
        if ReplenishmentRule."Maximum Quantity" = 0 then
            exit(0);
        if OnHand >= ReplenishmentRule."Minimum Quantity" then
            exit(0);
        if OnHand >= ReplenishmentRule."Maximum Quantity" then
            exit(0);

        exit(ReplenishmentRule."Maximum Quantity" - OnHand);
    end;

    local procedure HasOutstandingWork(var ReplenishmentRule: Record "WHA Replenishment Rule"): Boolean
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.SetRange("Task Type", WarehouseTask."Task Type"::WHAReplenishment);
        WarehouseTask.SetRange("Location Code", ReplenishmentRule."Location Code");
        WarehouseTask.SetRange("To Bin Code", ReplenishmentRule."Bin Code");
        WarehouseTask.SetRange("Item No.", ReplenishmentRule."Item No.");
        WarehouseTask.SetRange("Variant Code", ReplenishmentRule."Variant Code");
        WarehouseTask.SetFilter(Status, '<>%1&<>%2', WarehouseTask.Status::WHACompleted, WarehouseTask.Status::WHACancelled);
        exit(not WarehouseTask.IsEmpty());
    end;

    local procedure RaiseTask(var ReplenishmentRule: Record "WHA Replenishment Rule"; Needed: Decimal): Code[20]
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.Init();
        WarehouseTask.Validate("Task Type", WarehouseTask."Task Type"::WHAReplenishment);
        WarehouseTask.Validate(Description, CopyStr(StrSubstNo(TaskDescriptionLbl, ReplenishmentRule."Item No.", ReplenishmentRule."Bin Code"), 1, MaxStrLen(WarehouseTask.Description)));
        WarehouseTask.Validate("Location Code", ReplenishmentRule."Location Code");
        WarehouseTask.Validate("Item No.", ReplenishmentRule."Item No.");
        WarehouseTask."Variant Code" := ReplenishmentRule."Variant Code";
        if ReplenishmentRule."Unit of Measure Code" <> '' then
            WarehouseTask."Unit of Measure Code" := ReplenishmentRule."Unit of Measure Code";
        WarehouseTask.Validate(Quantity, Needed);
        WarehouseTask."From Bin Code" := ReplenishmentRule."Source Bin Code";
        WarehouseTask."To Bin Code" := ReplenishmentRule."Bin Code";
        WarehouseTask.Validate(Priority, PriorityFor(ReplenishmentRule));
        WarehouseTask."Due Date" := WorkDate();
        WarehouseTask.Insert(true);

        ReleaseIfSetupAsks(WarehouseTask);
        exit(WarehouseTask."No.");
    end;

    local procedure ReleaseIfSetupAsks(var WarehouseTask: Record "WHA Warehouse Task")
    var
        Setup: Record "WHA Repl. Setup";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        if WarehouseTask.Status <> WarehouseTask.Status::WHACreated then
            exit;

        Setup.SetLoadFields("Release Replenishment Work");
        if not Setup.Get() then
            exit;
        if not Setup."Release Replenishment Work" then
            exit;

        TaskLogic.Release(WarehouseTask);
    end;

    local procedure PriorityFor(var ReplenishmentRule: Record "WHA Replenishment Rule"): Integer
    var
        Setup: Record "WHA Repl. Setup";
    begin
        if ReplenishmentRule.Priority > 0 then
            exit(ReplenishmentRule.Priority);

        Setup.SetLoadFields("Default Priority");
        if not Setup.Get() then
            exit(0);
        exit(Setup."Default Priority");
    end;

    local procedure StampRule(var ReplenishmentRule: Record "WHA Replenishment Rule"; TaskNo: Code[20])
    begin
        ReplenishmentRule."Last Checked At" := CurrentDateTime;
        if TaskNo <> '' then
            ReplenishmentRule."Last Task No." := TaskNo;
        ReplenishmentRule.Modify(true);
    end;
}
