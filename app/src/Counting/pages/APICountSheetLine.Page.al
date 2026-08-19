namespace WarehouseAdvanced.Counting;

using WarehouseAdvanced.Core;

page 50505 "WHA API Count Sheet Line"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'counting';
    APIVersion = 'v1.0';
    EntityName = 'countSheetLine';
    EntitySetName = 'countSheetLines';
    EntityCaption = 'Count sheet line';
    EntitySetCaption = 'Count sheet lines';
    SourceTable = "WHA Count Sheet Line";
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
                field(sheetNumber; Rec."Sheet No.")
                {
                    Caption = 'Sheet number';
                }
                field(lineNumber; Rec."Line No.")
                {
                    Caption = 'Line number';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin code';
                }
                field(handlingUnitNumber; Rec."Handling Unit No.")
                {
                    Caption = 'Handling unit number';
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
                field(expectedQuantity; Rec."Expected Quantity")
                {
                    Caption = 'Expected quantity';
                    Editable = false;
                }
                field(countedQuantity; Rec."Counted Quantity")
                {
                    Caption = 'Counted quantity';
                }
                field(counted; Rec.Counted)
                {
                    Caption = 'Counted';
                    Editable = false;
                }
                field(variance; Rec.Variance)
                {
                    Caption = 'Variance';
                    Editable = false;
                }
                field(outOfTolerance; Rec."Out of Tolerance")
                {
                    Caption = 'Out of tolerance';
                    Editable = false;
                }
                field(approved; Rec.Approved)
                {
                    Caption = 'Approved';
                    Editable = false;
                }
                field(countedByUserId; Rec."Counted By User ID")
                {
                    Caption = 'Counted by user ID';
                    Editable = false;
                }
                field(countedDateTime; Rec."Counted At")
                {
                    Caption = 'Counted date time';
                    Editable = false;
                }
                field(approvedByUserId; Rec."Approved By User ID")
                {
                    Caption = 'Approved by user ID';
                    Editable = false;
                }
                field(postingQuantity; Rec."Posting Quantity")
                {
                    Caption = 'Posting quantity';
                    Editable = false;
                }
                field(posted; Rec.Posted)
                {
                    Caption = 'Posted';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified date time';
                    Editable = false;
                }
            }
        }
    }

    /// <summary>
    /// Accepts a difference that is bigger than the tolerance, so the sheet can be closed.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Approve(var ActionContext: WebServiceActionContext)
    var
        CountLineLogic: Codeunit "WHA Count Line Logic";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        CountLineLogic.Approve(Rec);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Count Sheet Line");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHACounting);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
