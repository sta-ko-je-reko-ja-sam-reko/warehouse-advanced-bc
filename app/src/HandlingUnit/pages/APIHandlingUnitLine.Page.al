namespace WarehouseAdvanced.HandlingUnit;

using WarehouseAdvanced.Core;

page 50056 "WHA API Handling Unit Line"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'handlingUnit';
    APIVersion = 'v1.0';
    EntityName = 'handlingUnitLine';
    EntitySetName = 'handlingUnitLines';
    EntityCaption = 'Handling unit line';
    EntitySetCaption = 'Handling unit lines';
    SourceTable = "WHA Handling Unit Line";
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
                field(handlingUnitNumber; Rec."Handling Unit No.")
                {
                    Caption = 'Handling unit number';
                }
                field(lineNumber; Rec."Line No.")
                {
                    Caption = 'Line number';
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item number';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of measure code';
                }
                field(lotNumber; Rec."Lot No.")
                {
                    Caption = 'Lot number';
                }
                field(serialNumber; Rec."Serial No.")
                {
                    Caption = 'Serial number';
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
