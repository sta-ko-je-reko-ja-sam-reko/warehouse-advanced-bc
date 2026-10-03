namespace WarehouseAdvanced.Slotting;

enum 55302 "WHA Proposal Status"
{
    Caption = 'Proposal status';
    Extensible = true;

    value(0; WHAOpen)
    {
        Caption = 'Open';
    }
    value(1; WHAAccepted)
    {
        Caption = 'Accepted';
    }
    value(2; WHARejected)
    {
        Caption = 'Rejected';
    }
}
