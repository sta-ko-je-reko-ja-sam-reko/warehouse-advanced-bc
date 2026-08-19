codeunit 51014 "WHA Test Posting Recorder" implements "WHA IInvtPosting"
{
    Access = Public;
    SingleInstance = true;

    var
        TempRecordedRequest: Record "WHA Posting Request" temporary;
        RecordedCount: Integer;
        DescriptionLbl: Label 'Records what it was asked to post and posts nothing. Test use only.';

    /// <summary>
    /// Keeps a copy of every line it is handed and marks each as posted, so a test can assert what a
    /// feature asked the ledger for without a ledger to ask.
    /// </summary>
    /// <param name="PostingRequest">The lines to post.</param>
    /// <returns>How many lines were recorded.</returns>
    procedure Post(var PostingRequest: Record "WHA Posting Request"): Integer
    var
        Copied: Integer;
    begin
        PostingRequest.Reset();
        if not PostingRequest.FindSet() then
            exit(0);

        repeat
            TempRecordedRequest := PostingRequest;
            RecordedCount += 1;
            TempRecordedRequest."Entry No." := RecordedCount;
            TempRecordedRequest.Posted := true;
            TempRecordedRequest.Insert(false);

            PostingRequest.Posted := true;
            PostingRequest.Modify(false);
            Copied += 1;
        until PostingRequest.Next() = 0;

        exit(Copied);
    end;

    /// <summary>
    /// Describes in one line what this way of posting does.
    /// </summary>
    /// <returns>A short description.</returns>
    procedure Describe(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Answers whether this way of posting writes to the item ledger. It says yes so that the features
    /// under test take the branch a real posting takes.
    /// </summary>
    /// <returns>True.</returns>
    procedure WritesToLedger(): Boolean
    begin
        exit(true);
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
    /// <param name="TempPostingRequest">Receives the recorded lines.</param>
    /// <returns>How many lines were recorded.</returns>
    procedure Recorded(var TempPostingRequest: Record "WHA Posting Request" temporary): Integer
    begin
        TempPostingRequest.Reset();
        TempPostingRequest.DeleteAll(false);

        TempRecordedRequest.Reset();
        if not TempRecordedRequest.FindSet() then
            exit(0);

        repeat
            TempPostingRequest := TempRecordedRequest;
            TempPostingRequest.Insert(false);
        until TempRecordedRequest.Next() = 0;

        exit(TempPostingRequest.Count());
    end;
}
