namespace WarehouseAdvanced.Slotting;

using Microsoft.Warehouse.Structure;
using WarehouseAdvanced.DirectedWork;

codeunit 50300 "WHA Slotting Mgt."
{
    Access = Public;

    var
        LocationMissingErr: Label 'Say which location to analyse. Velocity is a comparison between the items at one site, so it cannot be worked out for all of them at once.';
        AlreadyHandledErr: Label 'Proposal %1 has already been answered.', Comment = '%1 = the proposal entry number';
        NoDestinationErr: Label 'Proposal %1 does not say where to move the goods, so no work can be raised. Fill in where it should go, or accept it as a decision on its own.', Comment = '%1 = the proposal entry number';
        MoveDescriptionLbl: Label 'Re-slot %1 from %2 to %3', Comment = '%1 = the item number, %2 = the bin it is in now, %3 = the bin it is moving to';
        DateFormulaTok: Label '<-%1D>', Locked = true, Comment = '%1 = the number of days to look back';
        WrongBinReasonLbl: Label 'Class %1 is picked from a bin ranked %2, and its class needs %3.', Comment = '%1 = the velocity class, %2 = the ranking of the bin it is picked from, %3 = the ranking the class requires';

    /// <summary>
    /// Works out how fast every item moves at a location, from the picks the warehouse has already done,
    /// and gives each one a class. Re-running replaces the previous answer for that location: a velocity
    /// is a statement about a period, and two periods added together is a statement about neither.
    /// </summary>
    /// <param name="LocationCode">The location to analyse. Required.</param>
    /// <param name="FromDate">The first day to count. Blank uses the period from the setup.</param>
    /// <param name="ToDate">The last day to count. Blank means today.</param>
    /// <returns>How many items were measured.</returns>
    procedure Analyse(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Integer
    var
        ItemVelocity: Record "WHA Item Velocity";
        Measured: Integer;
    begin
        if LocationCode = '' then
            Error(LocationMissingErr);

        ResolveDates(FromDate, ToDate);
        ClearLocation(LocationCode);

        Measured := Gather(LocationCode, FromDate, ToDate);
        if Measured = 0 then
            exit(0);

        ApplyRanking(LocationCode);
        Classify(LocationCode);

        ItemVelocity.SetRange("Location Code", LocationCode);
        exit(ItemVelocity.Count());
    end;

    /// <summary>
    /// Proposes a move for every classified item that is picked from a bin worse than its class deserves.
    /// A proposal says a move is worth making; it does not say where to, because nothing in the app knows
    /// which good bin is free.
    /// </summary>
    /// <param name="LocationCode">The location to propose for.</param>
    /// <returns>How many proposals were made.</returns>
    procedure Propose(LocationCode: Code[10]): Integer
    var
        ItemVelocity: Record "WHA Item Velocity";
        Made: Integer;
        Required: Integer;
    begin
        if LocationCode = '' then
            Error(LocationMissingErr);

        ItemVelocity.SetRange("Location Code", LocationCode);
        ItemVelocity.SetFilter(Class, '<>%1', ItemVelocity.Class::WHAUnclassified);
        if not ItemVelocity.FindSet() then
            exit(0);

        repeat
            Required := RequiredRanking(ItemVelocity.Class);
            if ShouldPropose(ItemVelocity, Required) then
                if CreateProposal(ItemVelocity, Required) <> 0 then
                    Made += 1;
        until ItemVelocity.Next() = 0;

        exit(Made);
    end;

    /// <summary>
    /// Accepts a proposal, and raises the work to make the move when it says where the goods should go.
    /// </summary>
    /// <param name="SlottingProposal">The proposal to accept.</param>
    /// <returns>The number of the work raised, or blank when the proposal was accepted as a decision only.</returns>
    procedure Accept(var SlottingProposal: Record "WHA Slotting Proposal"): Code[20]
    var
        TaskNo: Code[20];
    begin
        CheckOpen(SlottingProposal);

        if SlottingProposal."To Bin Code" <> '' then
            TaskNo := RaiseMove(SlottingProposal);

        SlottingProposal.Status := SlottingProposal.Status::WHAAccepted;
        SlottingProposal."Task No." := TaskNo;
        StampHandled(SlottingProposal);
        exit(TaskNo);
    end;

    /// <summary>
    /// Turns a proposal down. The proposal is kept: what was suggested and refused is the only record of
    /// why stock sits where it sits.
    /// </summary>
    /// <param name="SlottingProposal">The proposal to reject.</param>
    procedure Reject(var SlottingProposal: Record "WHA Slotting Proposal")
    begin
        CheckOpen(SlottingProposal);

        SlottingProposal.Status := SlottingProposal.Status::WHARejected;
        StampHandled(SlottingProposal);
    end;

    /// <summary>
    /// Raises the work for a proposal that was accepted without anywhere to move to, once somebody has
    /// filled the destination in.
    /// </summary>
    /// <param name="SlottingProposal">The accepted proposal.</param>
    /// <returns>The number of the work raised.</returns>
    procedure RaiseWork(var SlottingProposal: Record "WHA Slotting Proposal"): Code[20]
    var
        TaskNo: Code[20];
    begin
        if SlottingProposal."To Bin Code" = '' then
            Error(NoDestinationErr, SlottingProposal."Entry No.");

        TaskNo := RaiseMove(SlottingProposal);
        SlottingProposal."Task No." := TaskNo;
        SlottingProposal.Modify(true);
        exit(TaskNo);
    end;

    /// <summary>
    /// Describes in one line what the setup ranks items on.
    /// </summary>
    /// <returns>A short description in the user's language.</returns>
    procedure DescribeBasis(): Text
    var
        VelocityBasis: Interface "WHA IVelocityBasis";
    begin
        VelocityBasis := ConfiguredBasis();
        exit(VelocityBasis.Describe());
    end;

    local procedure Gather(LocationCode: Code[10]; FromDate: Date; ToDate: Date): Integer
    var
        WarehouseTask: Record "WHA Warehouse Task";
        Counted: Integer;
    begin
        WarehouseTask.SetCurrentKey(Status, "Location Code");
        WarehouseTask.SetRange(Status, WarehouseTask.Status::WHACompleted);
        WarehouseTask.SetRange("Location Code", LocationCode);
        WarehouseTask.SetRange("Task Type", WarehouseTask."Task Type"::WHAPick);
        WarehouseTask.SetFilter("Item No.", '<>%1', '');
        if not WarehouseTask.FindSet() then
            exit(0);

        repeat
            if CompletedWithin(WarehouseTask, FromDate, ToDate) then begin
                AddMovement(WarehouseTask, FromDate, ToDate);
                Counted += 1;
            end;
        until WarehouseTask.Next() = 0;

        exit(Counted);
    end;

    local procedure AddMovement(var WarehouseTask: Record "WHA Warehouse Task"; FromDate: Date; ToDate: Date)
    var
        ItemVelocity: Record "WHA Item Velocity";
        Quantity: Decimal;
    begin
        Quantity := WarehouseTask."Quantity Handled";
        if Quantity <= 0 then
            Quantity := WarehouseTask.Quantity;

        if not ItemVelocity.Get(WarehouseTask."Location Code", WarehouseTask."Item No.", WarehouseTask."Variant Code") then begin
            ItemVelocity.Init();
            ItemVelocity."Location Code" := WarehouseTask."Location Code";
            ItemVelocity."Item No." := WarehouseTask."Item No.";
            ItemVelocity."Variant Code" := WarehouseTask."Variant Code";
            ItemVelocity."From Date" := FromDate;
            ItemVelocity."To Date" := ToDate;
            ItemVelocity."Calculated At" := CurrentDateTime;
            ItemVelocity.Insert(true);
        end;

        ItemVelocity.Movements += 1;
        ItemVelocity."Quantity Moved" += Quantity;
        if WarehouseTask."From Bin Code" <> '' then
            ItemVelocity."Main Bin Code" := WarehouseTask."From Bin Code";
        ItemVelocity.Modify(true);
    end;

    local procedure ApplyRanking(LocationCode: Code[10])
    var
        ItemVelocity: Record "WHA Item Velocity";
        VelocityBasis: Interface "WHA IVelocityBasis";
    begin
        VelocityBasis := ConfiguredBasis();

        ItemVelocity.SetRange("Location Code", LocationCode);
        if not ItemVelocity.FindSet(true) then
            exit;

        repeat
            ItemVelocity."Rank Value" := VelocityBasis.Rank(ItemVelocity);
            ItemVelocity."Main Bin Ranking" := RankingOf(ItemVelocity."Location Code", ItemVelocity."Main Bin Code");
            ItemVelocity.Modify(true);
        until ItemVelocity.Next() = 0;
    end;

    local procedure Classify(LocationCode: Code[10])
    var
        ItemVelocity: Record "WHA Item Velocity";
        Total: Decimal;
        Running: Decimal;
        Share: Decimal;
    begin
        Total := TotalRankValue(LocationCode);
        if Total <= 0 then
            exit;

        ItemVelocity.SetCurrentKey("Location Code", "Rank Value");
        ItemVelocity.SetAscending("Rank Value", false);
        ItemVelocity.SetRange("Location Code", LocationCode);
        if not ItemVelocity.FindSet(true) then
            exit;

        repeat
            Running += ItemVelocity."Rank Value";
            Share := Running / Total * 100;
            ItemVelocity.Class := ClassFor(ItemVelocity, Share);
            ItemVelocity.Modify(true);
        until ItemVelocity.Next() = 0;
    end;

    local procedure ClassFor(var ItemVelocity: Record "WHA Item Velocity"; Share: Decimal): Enum "WHA Velocity Class"
    var
        Setup: Record "WHA Slotting Setup";
        Class: Enum "WHA Velocity Class";
    begin
        Setup.SetLoadFields("Class A Percent", "Class B Percent", "Min Movements");
        if not Setup.Get() then
            exit(Class::WHAUnclassified);
        if ItemVelocity.Movements < Setup."Min Movements" then
            exit(Class::WHAUnclassified);

        if Share <= Setup."Class A Percent" then
            exit(Class::WHAClassA);
        if Share <= Setup."Class A Percent" + Setup."Class B Percent" then
            exit(Class::WHAClassB);
        exit(Class::WHAClassC);
    end;

    local procedure ShouldPropose(var ItemVelocity: Record "WHA Item Velocity"; Required: Integer): Boolean
    begin
        if Required <= 0 then
            exit(false);
        if ItemVelocity."Main Bin Code" = '' then
            exit(false);
        if ItemVelocity."Main Bin Ranking" >= Required then
            exit(false);

        exit(not HasOpenProposal(ItemVelocity));
    end;

    local procedure CreateProposal(var ItemVelocity: Record "WHA Item Velocity"; Required: Integer): Integer
    var
        SlottingProposal: Record "WHA Slotting Proposal";
    begin
        SlottingProposal.Init();
        SlottingProposal."Location Code" := ItemVelocity."Location Code";
        SlottingProposal."Item No." := ItemVelocity."Item No.";
        SlottingProposal."Variant Code" := ItemVelocity."Variant Code";
        SlottingProposal.Class := ItemVelocity.Class;
        SlottingProposal."From Bin Code" := ItemVelocity."Main Bin Code";
        SlottingProposal."From Bin Ranking" := ItemVelocity."Main Bin Ranking";
        SlottingProposal."Required Bin Ranking" := Required;
        SlottingProposal.Reason := CopyStr(StrSubstNo(WrongBinReasonLbl, ItemVelocity.Class, ItemVelocity."Main Bin Ranking", Required), 1, MaxStrLen(SlottingProposal.Reason));
        SlottingProposal.Insert(true);
        exit(SlottingProposal."Entry No.");
    end;

    local procedure HasOpenProposal(var ItemVelocity: Record "WHA Item Velocity"): Boolean
    var
        SlottingProposal: Record "WHA Slotting Proposal";
    begin
        SlottingProposal.SetCurrentKey("Location Code", Status);
        SlottingProposal.SetRange("Location Code", ItemVelocity."Location Code");
        SlottingProposal.SetRange(Status, SlottingProposal.Status::WHAOpen);
        SlottingProposal.SetRange("Item No.", ItemVelocity."Item No.");
        SlottingProposal.SetRange("Variant Code", ItemVelocity."Variant Code");
        exit(not SlottingProposal.IsEmpty());
    end;

    local procedure RaiseMove(var SlottingProposal: Record "WHA Slotting Proposal"): Code[20]
    var
        WarehouseTask: Record "WHA Warehouse Task";
    begin
        WarehouseTask.Init();
        WarehouseTask.Validate("Task Type", WarehouseTask."Task Type"::WHAMovement);
        WarehouseTask.Validate(Description, CopyStr(StrSubstNo(MoveDescriptionLbl, SlottingProposal."Item No.", SlottingProposal."From Bin Code", SlottingProposal."To Bin Code"), 1, MaxStrLen(WarehouseTask.Description)));
        WarehouseTask.Validate("Location Code", SlottingProposal."Location Code");
        WarehouseTask.Validate("Item No.", SlottingProposal."Item No.");
        WarehouseTask."Variant Code" := SlottingProposal."Variant Code";
        WarehouseTask."From Bin Code" := SlottingProposal."From Bin Code";
        WarehouseTask."To Bin Code" := SlottingProposal."To Bin Code";
        WarehouseTask."Due Date" := WorkDate();
        WarehouseTask.Insert(true);
        exit(WarehouseTask."No.");
    end;

    local procedure CheckOpen(var SlottingProposal: Record "WHA Slotting Proposal")
    begin
        if SlottingProposal.Status <> SlottingProposal.Status::WHAOpen then
            Error(AlreadyHandledErr, SlottingProposal."Entry No.");
    end;

    local procedure StampHandled(var SlottingProposal: Record "WHA Slotting Proposal")
    begin
        SlottingProposal."Handled By User ID" := CopyStr(UserId(), 1, MaxStrLen(SlottingProposal."Handled By User ID"));
        SlottingProposal."Handled At" := CurrentDateTime;
        SlottingProposal.Modify(true);
    end;

    local procedure ClearLocation(LocationCode: Code[10])
    var
        ItemVelocity: Record "WHA Item Velocity";
    begin
        ItemVelocity.SetRange("Location Code", LocationCode);
        ItemVelocity.DeleteAll(false);
    end;

    local procedure TotalRankValue(LocationCode: Code[10]): Decimal
    var
        ItemVelocity: Record "WHA Item Velocity";
        Total: Decimal;
    begin
        ItemVelocity.SetLoadFields("Rank Value");
        ItemVelocity.SetRange("Location Code", LocationCode);
        if not ItemVelocity.FindSet() then
            exit(0);

        repeat
            Total += ItemVelocity."Rank Value";
        until ItemVelocity.Next() = 0;

        exit(Total);
    end;

    local procedure RankingOf(LocationCode: Code[10]; BinCode: Code[20]): Integer
    var
        Bin: Record Bin;
    begin
        if BinCode = '' then
            exit(0);

        Bin.SetLoadFields("Bin Ranking");
        if not Bin.Get(LocationCode, BinCode) then
            exit(0);
        exit(Bin."Bin Ranking");
    end;

    local procedure RequiredRanking(Class: Enum "WHA Velocity Class"): Integer
    var
        Setup: Record "WHA Slotting Setup";
    begin
        Setup.SetLoadFields("Class A Min Bin Ranking", "Class B Min Bin Ranking");
        if not Setup.Get() then
            exit(0);

        case Class of
            Class::WHAClassA:
                exit(Setup."Class A Min Bin Ranking");
            Class::WHAClassB:
                exit(Setup."Class B Min Bin Ranking");
        end;
        exit(0);
    end;

    local procedure CompletedWithin(var WarehouseTask: Record "WHA Warehouse Task"; FromDate: Date; ToDate: Date): Boolean
    var
        CompletedOn: Date;
    begin
        if WarehouseTask."Completed At" = 0DT then
            exit(false);

        CompletedOn := DT2Date(WarehouseTask."Completed At");
        exit((CompletedOn >= FromDate) and (CompletedOn <= ToDate));
    end;

    local procedure ResolveDates(var FromDate: Date; var ToDate: Date)
    var
        Setup: Record "WHA Slotting Setup";
        Days: Integer;
    begin
        if ToDate = 0D then
            ToDate := WorkDate();
        if FromDate <> 0D then
            exit;

        Days := 90;
        Setup.SetLoadFields("Analysis Period Days");
        if Setup.Get() then
            if Setup."Analysis Period Days" > 0 then
                Days := Setup."Analysis Period Days";

        FromDate := CalcDate(StrSubstNo(DateFormulaTok, Days), ToDate);
    end;

    local procedure ConfiguredBasis(): Enum "WHA Velocity Basis"
    var
        Setup: Record "WHA Slotting Setup";
        Basis: Enum "WHA Velocity Basis";
    begin
        Setup.SetLoadFields(Basis);
        if not Setup.Get() then
            exit(Basis::WHAByMovements);
        exit(Setup.Basis);
    end;
}
