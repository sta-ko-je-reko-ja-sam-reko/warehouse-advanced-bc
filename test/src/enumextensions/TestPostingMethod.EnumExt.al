enumextension 51000 "WHA Test Posting Method" extends "WHA Posting Method"
{
    value(51000; WHATestRecorder)
    {
        Caption = 'Record what would be posted (test use only)';
        Implementation = "WHA IInvtPosting" = "WHA Test Posting Recorder";
    }
}
