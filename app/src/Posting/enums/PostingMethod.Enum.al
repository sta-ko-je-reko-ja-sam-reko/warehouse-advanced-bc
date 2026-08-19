namespace WarehouseAdvanced.Posting;

enum 50751 "WHA Posting Method" implements "WHA IInvtPosting"
{
    Caption = 'Posting method';
    Extensible = true;
    DefaultImplementation = "WHA IInvtPosting" = "WHA No Invt. Posting";

    value(0; WHANone)
    {
        Caption = 'Do not post';
        Implementation = "WHA IInvtPosting" = "WHA No Invt. Posting";
    }
    value(1; WHAJournalLines)
    {
        Caption = 'Put the lines in an item journal';
        Implementation = "WHA IInvtPosting" = "WHA Jnl. Line Posting";
    }
    value(2; WHAPostDirect)
    {
        Caption = 'Post to the item ledger';
        Implementation = "WHA IInvtPosting" = "WHA Direct Posting";
    }
}
