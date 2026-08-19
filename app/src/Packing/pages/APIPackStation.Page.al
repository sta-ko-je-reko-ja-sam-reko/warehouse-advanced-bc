namespace WarehouseAdvanced.Packing;

using WarehouseAdvanced.Core;

page 50405 "WHA API Pack Station"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'packing';
    APIVersion = 'v1.0';
    EntityName = 'packStation';
    EntitySetName = 'packStations';
    EntityCaption = 'Packing station';
    EntitySetCaption = 'Packing stations';
    SourceTable = "WHA Pack Station";
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
                field(code; Rec."Code")
                {
                    Caption = 'Code';
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
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
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
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAPacking);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAPacking);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAPacking);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
