namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

enumextension 55200 "WHA Task Activity Provider" extends "WHA Activity Provider"
{
    value(55200; WHADirectedWork)
    {
        Caption = 'Directed work';
        Implementation = "WHA IActivityCues" = "WHA Task Activity Cues";
    }
}
