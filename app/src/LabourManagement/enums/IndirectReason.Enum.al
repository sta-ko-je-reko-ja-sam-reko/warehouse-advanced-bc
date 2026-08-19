namespace WarehouseAdvanced.LabourManagement;

enum 50351 "WHA Indirect Reason"
{
    Caption = 'Indirect reason';
    Extensible = true;

    value(0; WHANone)
    {
        Caption = ' ';
    }
    value(1; WHABreak)
    {
        Caption = 'Break';
    }
    value(2; WHACleaning)
    {
        Caption = 'Cleaning';
    }
    value(3; WHAMeeting)
    {
        Caption = 'Meeting or briefing';
    }
    value(4; WHATraining)
    {
        Caption = 'Training';
    }
    value(5; WHAWaiting)
    {
        Caption = 'Waiting for work';
    }
    value(6; WHAEquipment)
    {
        Caption = 'Equipment problem';
    }
    value(7; WHAOther)
    {
        Caption = 'Other';
    }
}
