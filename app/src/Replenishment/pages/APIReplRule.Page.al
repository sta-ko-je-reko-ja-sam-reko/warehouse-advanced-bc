namespace WarehouseAdvanced.Replenishment;

using WarehouseAdvanced.Core;

page 50253 "WHA API Repl. Rule"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'replenishment';
    APIVersion = 'v1.0';
    EntityName = 'replenishmentRule';
    EntitySetName = 'replenishmentRules';
    EntityCaption = 'Replenishment rule';
    EntitySetCaption = 'Replenishment rules';
    SourceTable = "WHA Replenishment Rule";
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
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item number';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of measure code';
                }
                field(minimumQuantity; Rec."Minimum Quantity")
                {
                    Caption = 'Minimum quantity';
                }
                field(maximumQuantity; Rec."Maximum Quantity")
                {
                    Caption = 'Maximum quantity';
                }
                field(method; Rec.Method)
                {
                    Caption = 'Method';
                }
                field(sourceBinCode; Rec."Source Bin Code")
                {
                    Caption = 'Source bin code';
                }
                field(priority; Rec.Priority)
                {
                    Caption = 'Priority';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(lastCheckedDateTime; Rec."Last Checked At")
                {
                    Caption = 'Last checked date time';
                    Editable = false;
                }
                field(lastTaskNumber; Rec."Last Task No.")
                {
                    Caption = 'Last task number';
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
    /// Measures the rule's bin and raises the work to top it up, if it has run low.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Replenish(var ActionContext: WebServiceActionContext)
    var
        ReplenishmentMgt: Codeunit "WHA Replenishment Mgt.";
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAReplenishment);
        ReplenishmentMgt.RunRule(Rec);
        SetActionResponse(ActionContext);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAReplenishment);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAReplenishment);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAReplenishment);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Repl. Rule");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
