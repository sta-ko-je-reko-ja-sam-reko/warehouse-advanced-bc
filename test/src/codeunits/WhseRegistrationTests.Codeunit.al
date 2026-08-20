codeunit 51017 "WHA Whse. Registration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocationTok: Label 'WHAREG', Locked = true;
        FromBinTok: Label 'WHAREG-FROM', Locked = true;
        ToBinTok: Label 'WHAREG-TO', Locked = true;
        ItemTok: Label 'WHA-REG-IT', Locked = true;
        OtherItemTok: Label 'WHA-REG-IT2', Locked = true;

    [Test]
    procedure NotTellingBusinessCentralRecordsNothing()
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        NoWhseRegistration: Codeunit "WHA No Whse. Registration";
    begin
        // [SCENARIO] The method a fresh install lands on takes nothing and leaves the request alone, so a
        // warehouse that has not asked for this is in exactly the state it was in before.
        AddMoveLine(TempMoveRequest, 1, ItemTok, 5);

        Assert.AreEqual(0, NoWhseRegistration.Register(TempMoveRequest), 'Recording nothing should take no lines.');

        TempMoveRequest.FindFirst();
        Assert.IsFalse(TempMoveRequest.Registered, 'A line nobody recorded should not claim to have been registered.');
    end;

    [Test]
    procedure NotTellingBusinessCentralLeavesBinContentAlone()
    var
        NoWhseRegistration: Codeunit "WHA No Whse. Registration";
    begin
        // [SCENARIO] The default is honest about its consequence: the app and Business Central will hold
        // two different pictures of the same shelf.
        Assert.IsFalse(NoWhseRegistration.UpdatesBinContent(), 'Recording nothing should not claim to maintain bin content.');
    end;

    [Test]
    procedure RegisteringAMovementMaintainsBinContent()
    var
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] The whole point of the other method, stated where setup can read it.
        Assert.IsTrue(WhseJnlRegistration.UpdatesBinContent(), 'Registering a movement should maintain bin content.');
    end;

    [Test]
    procedure EveryMethodExplainsItself()
    var
        NoWhseRegistration: Codeunit "WHA No Whse. Registration";
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] Setup shows what the choice does before the floor starts moving stock, so neither
        // way of recording a move may be silent about itself.
        Assert.AreNotEqual('', NoWhseRegistration.Describe(), 'Recording nothing should still say so.');
        Assert.AreNotEqual('', WhseJnlRegistration.Describe(), 'Registering a movement should say what it does.');
    end;

    [Test]
    procedure AMoveWithoutAnItemIsRefused()
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] A half-filled line is a bug in whoever built it, and is heard about here rather than
        // three layers down inside Business Central.
        AddMoveLine(TempMoveRequest, 1, '', 5);

        asserterror WhseJnlRegistration.Register(TempMoveRequest);

        Assert.ExpectedError('no item on it');
    end;

    [Test]
    procedure AMoveWithoutAQuantityIsRefused()
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] Nothing moved is not a move.
        AddMoveLine(TempMoveRequest, 1, ItemTok, 0);

        asserterror WhseJnlRegistration.Register(TempMoveRequest);

        Assert.ExpectedError('no quantity on it');
    end;

    [Test]
    procedure AMoveWithoutALocationIsRefused()
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] Without a location there is no bin for the move to be recorded against.
        AddMoveLine(TempMoveRequest, 1, ItemTok, 5);
        TempMoveRequest."Location Code" := '';
        TempMoveRequest.Modify(false);

        asserterror WhseJnlRegistration.Register(TempMoveRequest);

        Assert.ExpectedError('no location on it');
    end;

    [Test]
    procedure AMoveWithOnlyOneEndIsRefused()
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] Goods leaving the warehouse are accounted for by posting the document. A one-sided
        // move would be an adjustment this app never decided to make.
        AddMoveLine(TempMoveRequest, 1, ItemTok, 5);
        TempMoveRequest."To Bin Code" := '';
        TempMoveRequest.Modify(false);

        asserterror WhseJnlRegistration.Register(TempMoveRequest);

        Assert.ExpectedError('where they went');
    end;

    [Test]
    procedure AMoveBackIntoTheSameBinIsRefused()
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] Taking from a bin and putting it straight back is not something to record.
        AddMoveLine(TempMoveRequest, 1, ItemTok, 5);
        TempMoveRequest."To Bin Code" := TempMoveRequest."From Bin Code";
        TempMoveRequest.Modify(false);

        asserterror WhseJnlRegistration.Register(TempMoveRequest);

        Assert.ExpectedError('which is not a move');
    end;

    [Test]
    procedure ALocationThatKeepsNoBinsIsPassedOver()
    var
        TempMoveRequest: Record "WHA Whse. Move Request" temporary;
        WhseJnlRegistration: Codeunit "WHA Whse. Jnl. Registration";
    begin
        // [SCENARIO] Where Business Central keeps no bins there is no bin-level record to keep true, so
        // the app moving the goods in its own records is the whole of it. The move is passed over rather
        // than refused, because nothing is wrong with it.
        EnsureWarehouse();
        AddMoveLine(TempMoveRequest, 1, ItemTok, 5);

        Assert.AreEqual(0, WhseJnlRegistration.Register(TempMoveRequest), 'A location without bins should have nothing registered against it.');

        TempMoveRequest.FindFirst();
        Assert.IsFalse(TempMoveRequest.Registered, 'A move that was passed over should not claim to have been registered.');
    end;

    [Test]
    procedure AnItemJobBecomesOneMove()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] A job that names an item moves that item alone, and tells Business Central which bin
        // it came from and which one it went to.
        ConfigureRegistration();
        Recorder.Forget();

        CreateItemTask(WarehouseTask, 'WHA-REG-ITEM');
        FinishInFull(WarehouseTask);

        Assert.AreEqual(1, Recorder.Recorded(TempRecorded), 'An item job should hand over one move.');

        TempRecorded.FindFirst();
        Assert.AreEqual(ItemTok, TempRecorded."Item No.", 'The move should carry the item the job named.');
        Assert.AreEqual(10, TempRecorded.Quantity, 'The move should carry what the job handled.');
        Assert.AreEqual(FromBinTok, TempRecorded."From Bin Code", 'The move should start where the job did.');
        Assert.AreEqual(ToBinTok, TempRecorded."To Bin Code", 'The move should end where the job did.');
        Assert.AreEqual('WHA-REG-ITEM', TempRecorded."Reference No.", 'The move should name the job it came from.');
    end;

    [Test]
    procedure AShortPickMovesWhatWasFound()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        Reason: Enum "WHA Whse. Short Reason";
    begin
        // [SCENARIO] A job finished with less than it asked for tells Business Central about what actually
        // moved, not about what was asked for.
        ConfigureRegistration();
        Recorder.Forget();

        CreateItemTask(WarehouseTask, 'WHA-REG-SHORT');
        StartTask(WarehouseTask);
        TaskLogic.CompleteShort(WarehouseTask, 4, Reason::WHANotEnough);

        Assert.AreEqual(1, Recorder.Recorded(TempRecorded), 'A short pick that found something should hand over one move.');

        TempRecorded.FindFirst();
        Assert.AreEqual(4, TempRecorded.Quantity, 'The move should carry what was found, not what was asked for.');
    end;

    [Test]
    procedure AJobThatFoundNothingIsNotAMove()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
        Reason: Enum "WHA Whse. Short Reason";
    begin
        // [SCENARIO] A job finished short with nothing found moved nothing, so Business Central hears
        // nothing.
        ConfigureRegistration();
        Recorder.Forget();

        CreateItemTask(WarehouseTask, 'WHA-REG-NOTHING');
        StartTask(WarehouseTask);
        TaskLogic.CompleteShort(WarehouseTask, 0, Reason::WHANotEnough);

        Assert.AreEqual(0, Recorder.Recorded(TempRecorded), 'A job that found nothing should hand over no move.');
    end;

    [Test]
    procedure AJobWithNoDestinationIsNotAMove()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] A pick that ends at a shipment has no destination bin. What happens to that stock is
        // decided by posting the shipment, and inventing a move here would say otherwise.
        ConfigureRegistration();
        Recorder.Forget();

        CreateItemTask(WarehouseTask, 'WHA-REG-NODEST');
        WarehouseTask."To Bin Code" := '';
        WarehouseTask.Modify(true);
        FinishInFull(WarehouseTask);

        Assert.AreEqual(0, Recorder.Recorded(TempRecorded), 'A job with no destination should hand over no move.');
    end;

    [Test]
    procedure AJobWithNoSourceIsNotAMove()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] A put-away of goods that have just been received has no source bin. The receipt is
        // what brings them into stock, not this.
        ConfigureRegistration();
        Recorder.Forget();

        CreateItemTask(WarehouseTask, 'WHA-REG-NOSRC');
        WarehouseTask."From Bin Code" := '';
        WarehouseTask.Modify(true);
        FinishInFull(WarehouseTask);

        Assert.AreEqual(0, Recorder.Recorded(TempRecorded), 'A job with no source should hand over no move.');
    end;

    [Test]
    procedure AJobBackIntoTheSameBinIsNotAMove()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] A job whose two ends are the same bin moved nothing worth recording.
        ConfigureRegistration();
        Recorder.Forget();

        CreateItemTask(WarehouseTask, 'WHA-REG-SAMEBIN');
        WarehouseTask."To Bin Code" := CopyStr(FromBinTok, 1, MaxStrLen(WarehouseTask."To Bin Code"));
        WarehouseTask.Modify(true);
        FinishInFull(WarehouseTask);

        Assert.AreEqual(0, Recorder.Recorded(TempRecorded), 'A job that ends where it started should hand over no move.');
    end;

    [Test]
    procedure APalletJobMovesEveryLineOnThePallet()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] Naming a handling unit on a job moves the whole unit, so everything on it is a move.
        // The bin it came from is the unit's own, because a pallet job need not say where the pallet is.
        ConfigureRegistration();
        Recorder.Forget();

        CreatePalletTask(WarehouseTask, 'WHA-REG-HU', 'WHA-REG-UNIT');
        FinishInFull(WarehouseTask);

        Assert.AreEqual(2, Recorder.Recorded(TempRecorded), 'Both lines on the pallet should be handed over.');

        TempRecorded.SetRange("Item No.", ItemTok);
        TempRecorded.FindFirst();
        Assert.AreEqual(6, TempRecorded.Quantity, 'The move should carry what is on the pallet line.');
        Assert.AreEqual('LOT-A', TempRecorded."Lot No.", 'The move should carry the lot the pallet line names.');
    end;

    [Test]
    procedure APalletMovesFromWhereItWasStanding()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] The move is handed over before the app moves the pallet, because the bin the goods
        // came from is still readable then and is not afterwards.
        ConfigureRegistration();
        Recorder.Forget();

        CreatePalletTask(WarehouseTask, 'WHA-REG-FROM', 'WHA-REG-FROM-UNIT');
        FinishInFull(WarehouseTask);

        Recorder.Recorded(TempRecorded);
        TempRecorded.SetRange("Item No.", ItemTok);
        TempRecorded.FindFirst();

        Assert.AreEqual(FromBinTok, TempRecorded."From Bin Code", 'The move should start at the bin the pallet stood in before it was moved.');
        Assert.AreEqual(ToBinTok, TempRecorded."To Bin Code", 'The move should end at the bin the job named.');
    end;

    [Test]
    procedure APalletAtAnotherLocationIsNotAMove()
    var
        HandlingUnit: Record "WHA Handling Unit";
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] Goods crossing locations are a transfer, not a bin move, and this module does not
        // pretend otherwise.
        ConfigureRegistration();
        Recorder.Forget();

        CreatePalletTask(WarehouseTask, 'WHA-REG-ELSE', 'WHA-REG-ELSE-UNIT');

        HandlingUnit.Get('WHA-REG-ELSE-UNIT');
        HandlingUnit."Location Code" := 'WHA-OTHER';
        HandlingUnit.Modify(false);

        FinishInFull(WarehouseTask);

        Assert.AreEqual(0, Recorder.Recorded(TempRecorded), 'A pallet standing somewhere else should hand over no move.');
    end;

    [Test]
    procedure FinishingAJobTellsNobodyWhenNobodyAskedForIt()
    var
        TempRecorded: Record "WHA Whse. Move Request" temporary;
        WarehouseTask: Record "WHA Warehouse Task";
        Recorder: Codeunit "WHA Test Whse. Reg. Recorder";
    begin
        // [SCENARIO] A warehouse that has not chosen to tell Business Central is left exactly as it was.
        // This is the value a fresh install and every upgrade lands on.
        ConfigureNoRegistration();
        Recorder.Forget();

        CreatePalletTask(WarehouseTask, 'WHA-REG-QUIET', 'WHA-REG-QUIET-UNIT');
        FinishInFull(WarehouseTask);

        Assert.AreEqual(0, Recorder.Recorded(TempRecorded), 'Finishing the job should tell nobody when the warehouse has not asked for it.');
    end;

    local procedure AddMoveLine(var MoveRequest: Record "WHA Whse. Move Request"; EntryNo: Integer; ItemNo: Code[20]; Quantity: Decimal)
    begin
        MoveRequest.Init();
        MoveRequest."Entry No." := EntryNo;
        MoveRequest."Item No." := ItemNo;
        MoveRequest.Quantity := Quantity;
        MoveRequest."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(MoveRequest."Location Code"));
        MoveRequest."From Bin Code" := CopyStr(FromBinTok, 1, MaxStrLen(MoveRequest."From Bin Code"));
        MoveRequest."To Bin Code" := CopyStr(ToBinTok, 1, MaxStrLen(MoveRequest."To Bin Code"));
        MoveRequest.Insert(false);
    end;

    local procedure CreateItemTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20])
    begin
        EnsureWarehouse();

        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(WarehouseTask."Location Code"));
        WarehouseTask."From Bin Code" := CopyStr(FromBinTok, 1, MaxStrLen(WarehouseTask."From Bin Code"));
        WarehouseTask."To Bin Code" := CopyStr(ToBinTok, 1, MaxStrLen(WarehouseTask."To Bin Code"));
        WarehouseTask."Item No." := CopyStr(ItemTok, 1, MaxStrLen(WarehouseTask."Item No."));
        WarehouseTask.Quantity := 10;
        WarehouseTask.Insert(true);
    end;

    local procedure CreatePalletTask(var WarehouseTask: Record "WHA Warehouse Task"; TaskNo: Code[20]; UnitNo: Code[20])
    begin
        EnsureWarehouse();
        EnsurePallet(UnitNo);

        WarehouseTask.Init();
        WarehouseTask."No." := TaskNo;
        WarehouseTask."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(WarehouseTask."Location Code"));
        WarehouseTask."Handling Unit No." := UnitNo;
        WarehouseTask."To Bin Code" := CopyStr(ToBinTok, 1, MaxStrLen(WarehouseTask."To Bin Code"));
        WarehouseTask.Insert(true);
    end;

    local procedure FinishInFull(var WarehouseTask: Record "WHA Warehouse Task")
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        StartTask(WarehouseTask);
        TaskLogic.Complete(WarehouseTask);
    end;

    local procedure StartTask(var WarehouseTask: Record "WHA Warehouse Task")
    var
        TaskLogic: Codeunit "WHA Warehouse Task Logic";
    begin
        TaskLogic.Release(WarehouseTask);
        TaskLogic.Assign(WarehouseTask, EnsureUser('WHA-REGISTRAR'));
        TaskLogic.Start(WarehouseTask);
    end;

    local procedure EnsurePallet(UnitNo: Code[20])
    var
        HandlingUnit: Record "WHA Handling Unit";
        HandlingUnitLine: Record "WHA Handling Unit Line";
    begin
        if HandlingUnit.Get(UnitNo) then
            exit;

        HandlingUnit.Init();
        HandlingUnit."No." := UnitNo;
        HandlingUnit."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(HandlingUnit."Location Code"));
        HandlingUnit."Bin Code" := CopyStr(FromBinTok, 1, MaxStrLen(HandlingUnit."Bin Code"));
        HandlingUnit.Insert(true);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Item No." := CopyStr(ItemTok, 1, MaxStrLen(HandlingUnitLine."Item No."));
        HandlingUnitLine."Lot No." := 'LOT-A';
        HandlingUnitLine.Quantity := 6;
        HandlingUnitLine.Insert(true);

        HandlingUnitLine.Init();
        HandlingUnitLine."Handling Unit No." := UnitNo;
        HandlingUnitLine."Item No." := CopyStr(OtherItemTok, 1, MaxStrLen(HandlingUnitLine."Item No."));
        HandlingUnitLine.Quantity := 3;
        HandlingUnitLine.Insert(true);
    end;

    local procedure EnsureWarehouse()
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        if not Location.Get(LocationTok) then begin
            Location.Init();
            Location.Code := CopyStr(LocationTok, 1, MaxStrLen(Location.Code));
            Location.Insert();
        end;

        if not Bin.Get(LocationTok, FromBinTok) then begin
            Bin.Init();
            Bin."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(Bin."Location Code"));
            Bin.Code := CopyStr(FromBinTok, 1, MaxStrLen(Bin.Code));
            Bin.Insert();
        end;

        if Bin.Get(LocationTok, ToBinTok) then
            exit;

        Bin.Init();
        Bin."Location Code" := CopyStr(LocationTok, 1, MaxStrLen(Bin."Location Code"));
        Bin.Code := CopyStr(ToBinTok, 1, MaxStrLen(Bin.Code));
        Bin.Insert();
    end;

    local procedure ConfigureRegistration()
    var
        Setup: Record "WHA Warehouse Task Setup";
        Method: Enum "WHA Whse. Reg. Method";
    begin
        EnsureSetup(Setup);
        Setup.Validate("Whse. Registration Method", Method::WHATestRecorder);
        Setup.Modify(true);
    end;

    local procedure ConfigureNoRegistration()
    var
        Setup: Record "WHA Warehouse Task Setup";
        Method: Enum "WHA Whse. Reg. Method";
    begin
        EnsureSetup(Setup);
        Setup.Validate("Whse. Registration Method", Method::WHANone);
        Setup.Modify(true);
    end;

    local procedure EnsureSetup(var Setup: Record "WHA Warehouse Task Setup")
    begin
        Setup.Reset();
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;

        Setup.Validate("Auto Release Tasks", false);
        Setup.Validate("Max Open Tasks Per User", 0);
        Setup.Validate("Write Back To Document", false);
        Setup.Modify(true);
    end;

    local procedure EnsureUser(UserName: Code[50]): Code[50]
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserName);
        if not User.IsEmpty() then
            exit(UserName);

        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := UserName;
        User.Insert();
        exit(UserName);
    end;
}
