namespace WarehouseAdvanced.HandlingUnit;

using WarehouseAdvanced.Core;

page 50053 "WHA API Handling Unit"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'handlingUnit';
    APIVersion = 'v1.0';
    EntityName = 'handlingUnit';
    EntitySetName = 'handlingUnits';
    EntityCaption = 'Handling unit';
    EntitySetCaption = 'Handling units';
    SourceTable = "WHA Handling Unit";
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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(sscc; Rec.SSCC)
                {
                    Caption = 'SSCC';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin code';
                }
                field(parentNumber; Rec."Parent No.")
                {
                    Caption = 'Parent number';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified date time';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAHandlingUnits);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAHandlingUnits);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAHandlingUnits);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
