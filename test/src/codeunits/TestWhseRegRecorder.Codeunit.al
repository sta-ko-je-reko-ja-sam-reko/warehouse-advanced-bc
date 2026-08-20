codeunit 51016 "WHA Test Whse. Reg. Recorder" implements "WHA IWhseRegistration"
{
    Access = Public;
    SingleInstance = true;

    var
        TempRecordedRequest: Record "WHA Whse. Move Request" temporary;
        RecordedCount: Integer;
        DescriptionLbl: Label 'Records what it was asked to register and registers nothing. Test use only.';

    /// <summary>
    /// Keeps a copy of every move it is handed and marks each as registered, so a test can assert what a
    /// finished job would tell Business Central without a warehouse to tell it to.
    /// </summary>
    /// <param name="MoveRequest">The moves to record.</param>
    /// <returns>How many moves were recorded.</returns>
    procedure Register(var MoveRequest: Record "WHA Whse. Move Request"): Integer
    var
        Copied: Integer;
    begin
        MoveRequest.Reset();
        if not MoveRequest.FindSet() then
            exit(0);

        repeat
            TempRecordedRequest := MoveRequest;
            RecordedCount += 1;
            TempRecordedRequest."Entry No." := RecordedCount;
            TempRecordedRequest.Registered := true;
            TempRecordedRequest.Insert(false);

            MoveRequest.Registered := true;
            MoveRequest.Modify(false);
            Copied += 1;
        until MoveRequest.Next() = 0;

        exit(Copied);
    end;

    /// <summary>
    /// Describes in one line what this way of recording a move does.
    /// </summary>
    /// <returns>A short description.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this way of recording a move maintains bin content.
    /// </summary>
    /// <returns>False. Nothing is written anywhere Business Central can see.</returns>
    procedure UpdatesBinContent(): Boolean
    begin
        exit(false);
    end;

    /// <summary>
    /// Throws away everything recorded so far. A test calls this first, because the recorder outlives the
    /// test that used it.
    /// </summary>
    procedure Forget()
    begin
        TempRecordedRequest.Reset();
        TempRecordedRequest.DeleteAll(false);
        RecordedCount := 0;
    end;

    /// <summary>
    /// Hands back everything recorded since the last clear.
    /// </summary>
    /// <param name="TempMoveRequest">Receives the recorded moves.</param>
    /// <returns>How many moves were recorded.</returns>
    procedure Recorded(var TempMoveRequest: Record "WHA Whse. Move Request" temporary): Integer
    begin
        TempMoveRequest.Reset();
        TempMoveRequest.DeleteAll(false);

        TempRecordedRequest.Reset();
        if not TempRecordedRequest.FindSet() then
            exit(0);

        repeat
            TempMoveRequest := TempRecordedRequest;
            TempMoveRequest.Insert(false);
        until TempRecordedRequest.Next() = 0;

        exit(TempMoveRequest.Count());
    end;
}
