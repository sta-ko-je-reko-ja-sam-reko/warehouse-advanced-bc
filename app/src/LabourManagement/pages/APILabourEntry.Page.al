namespace WarehouseAdvanced.LabourManagement;

page 50353 "WHA API Labour Entry"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'labourManagement';
    APIVersion = 'v1.0';
    EntityName = 'labourEntry';
    EntitySetName = 'labourEntries';
    EntityCaption = 'Labour entry';
    EntitySetCaption = 'Labour entries';
    SourceTable = "WHA Labour Entry";
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
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
                field(entryNumber; Rec."Entry No.")
                {
                    Caption = 'Entry number';
                }
                field(entryType; Rec."Entry Type")
                {
                    Caption = 'Entry type';
                }
                field(userId; Rec."User ID")
                {
                    Caption = 'User ID';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting date';
                }
                field(taskNumber; Rec."Task No.")
                {
                    Caption = 'Task number';
                }
                field(taskType; Rec."Task Type")
                {
                    Caption = 'Task type';
                }
                field(indirectReason; Rec."Indirect Reason")
                {
                    Caption = 'Indirect reason';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(quantityHandled; Rec."Quantity Handled")
                {
                    Caption = 'Quantity handled';
                }
                field(actualMinutes; Rec."Actual Minutes")
                {
                    Caption = 'Actual minutes';
                }
                field(expectedMinutes; Rec."Expected Minutes")
                {
                    Caption = 'Expected minutes';
                }
                field(performancePercent; Rec."Performance Percent")
                {
                    Caption = 'Performance percent';
                }
                field(measuredAgainstStandard; Rec."Measured Against Standard")
                {
                    Caption = 'Measured against standard';
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
