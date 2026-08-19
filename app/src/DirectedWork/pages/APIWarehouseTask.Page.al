namespace WarehouseAdvanced.DirectedWork;

using WarehouseAdvanced.Core;

page 50203 "WHA API Warehouse Task"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'directedWork';
    APIVersion = 'v1.0';
    EntityName = 'warehouseTask';
    EntitySetName = 'warehouseTasks';
    EntityCaption = 'Warehouse task';
    EntitySetCaption = 'Warehouse tasks';
    SourceTable = "WHA Warehouse Task";
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
                field(taskType; Rec."Task Type")
                {
                    Caption = 'Task type';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(fromBinCode; Rec."From Bin Code")
                {
                    Caption = 'From bin code';
                }
                field(toBinCode; Rec."To Bin Code")
                {
                    Caption = 'To bin code';
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
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of measure code';
                }
                field(priority; Rec.Priority)
                {
                    Caption = 'Priority';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due date';
                }
                field(assignedToUserId; Rec."Assigned To User ID")
                {
                    Caption = 'Assigned to user ID';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(assignedDateTime; Rec."Assigned At")
                {
                    Caption = 'Assigned date time';
                    Editable = false;
                }
                field(startedDateTime; Rec."Started At")
                {
                    Caption = 'Started date time';
                    Editable = false;
                }
                field(completedDateTime; Rec."Completed At")
                {
                    Caption = 'Completed date time';
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
    /// Makes the task available to the floor.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Release(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);
        TaskLogic.Release(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Records that the person the task is assigned to has started working it.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Start(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);
        TaskLogic.Start(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Records the work as done and moves the handling unit the task carried to its destination.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Complete(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);
        TaskLogic.Complete(Rec);
        SetActionResponse(ActionContext);
    end;

    /// <summary>
    /// Withdraws the task without deleting it.
    /// </summary>
    /// <param name="ActionContext">The web service action context supplied by the platform.</param>
    [ServiceEnabled]
    procedure Cancel(var ActionContext: WebServiceActionContext)
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);
        TaskLogic.Cancel(Rec);
        SetActionResponse(ActionContext);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        TaskLogic: Codeunit "WHA Warehouse Task Logic";

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"WHA API Warehouse Task");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
