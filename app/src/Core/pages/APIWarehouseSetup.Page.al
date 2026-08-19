namespace WarehouseAdvanced.Core;

page 50003 "WHA API Warehouse Setup"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'core';
    APIVersion = 'v1.0';
    EntityName = 'warehouseSetup';
    EntitySetName = 'warehouseSetups';
    EntityCaption = 'Warehouse setup';
    EntitySetCaption = 'Warehouse setups';
    SourceTable = "WHA Warehouse Setup";
    DelayedInsert = true;
    Extensible = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(handlingUnitNumberSeries; Rec."Handling Unit Nos.")
                {
                    Caption = 'Handling unit number series';
                }
                field(warehouseTaskNumberSeries; Rec."Warehouse Task Nos.")
                {
                    Caption = 'Warehouse task number series';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified date time';
                    Editable = false;
                }
            }
        }
    }
}
