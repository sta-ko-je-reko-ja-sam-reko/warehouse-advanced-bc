namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

enumextension 50200 "WHA Task Activity Provider" extends "WHA Activity Provider"
{
    value(50200; WHADirectedWork)
    {
        Caption = 'Directed work';
        Implementation = "WHA IActivityCues" = "WHA Task Activity Cues";
    }
}
