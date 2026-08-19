namespace WarehouseAdvanced.Core;

enum 50002 "WHA Activity Provider" implements "WHA IActivityCues"
{
    Caption = 'Activity provider';
    Extensible = true;
    DefaultImplementation = "WHA IActivityCues" = "WHA No Activity Cues";

    value(0; WHANone)
    {
        Caption = 'No activities';
        Implementation = "WHA IActivityCues" = "WHA No Activity Cues";
    }
}
