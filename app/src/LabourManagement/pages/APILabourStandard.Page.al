namespace WarehouseAdvanced.LabourManagement;

using WarehouseAdvanced.Core;

page 50354 "WHA API Labour Standard"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'labourManagement';
    APIVersion = 'v1.0';
    EntityName = 'labourStandard';
    EntitySetName = 'labourStandards';
    EntityCaption = 'Labour standard';
    EntitySetCaption = 'Labour standards';
    SourceTable = "WHA Labour Standard";
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
                field(taskType; Rec."Task Type")
                {
                    Caption = 'Task type';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(basis; Rec.Basis)
                {
                    Caption = 'Basis';
                }
                field(minutesPerJob; Rec."Minutes Per Job")
                {
                    Caption = 'Minutes per job';
                }
                field(minutesPerUnit; Rec."Minutes Per Unit")
                {
                    Caption = 'Minutes per unit';
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
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHALabourManagement);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHALabourManagement);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHALabourManagement);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
