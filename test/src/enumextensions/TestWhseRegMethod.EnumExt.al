enumextension 51001 "WHA Test Whse. Reg. Method" extends "WHA Whse. Reg. Method"
{
    value(51000; WHATestRecorder)
    {
        Caption = 'Record what would be registered (test use only)';
        Implementation = "WHA IWhseRegistration" = "WHA Test Whse. Reg. Recorder";
    }
}
