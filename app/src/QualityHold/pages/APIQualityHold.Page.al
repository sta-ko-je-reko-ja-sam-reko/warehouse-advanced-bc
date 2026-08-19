namespace WarehouseAdvanced.QualityHold;

page 50553 "WHA API Quality Hold"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'qualityHold';
    APIVersion = 'v1.0';
    EntityName = 'qualityHold';
    EntitySetName = 'qualityHolds';
    EntityCaption = 'Quality hold';
    EntitySetCaption = 'Quality holds';
    SourceTable = "WHA Quality Hold";
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
                field(handlingUnitNumber; Rec."Handling Unit No.")
                {
                    Caption = 'Handling unit number';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(binCode; Rec."Bin Code")
                {
                    Caption = 'Bin code';
                }
                field(reason; Rec.Reason)
                {
                    Caption = 'Reason';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(disposition; Rec.Disposition)
                {
                    Caption = 'Disposition';
                }
                field(cascadedFromEntryNumber; Rec."Cascaded From Entry No.")
                {
                    Caption = 'Cascaded from entry number';
                }
                field(heldByUserId; Rec."Held By User ID")
                {
                    Caption = 'Held by user ID';
                }
                field(heldDateTime; Rec."Held At")
                {
                    Caption = 'Held date time';
                }
                field(releasedByUserId; Rec."Released By User ID")
                {
                    Caption = 'Released by user ID';
                }
                field(releasedDateTime; Rec."Released At")
                {
                    Caption = 'Released date time';
                }
                field(previousUnitStatus; Rec."Previous Unit Status")
                {
                    Caption = 'Previous unit status';
                }
                field(posted; Rec.Posted)
                {
                    Caption = 'Posted';
                    Editable = false;
                }
                field(postedQuantity; Rec."Posted Quantity")
                {
                    Caption = 'Posted quantity';
                    Editable = false;
                }
                field(postingDocumentNumber; Rec."Posting Document No.")
                {
                    Caption = 'Posting document number';
                    Editable = false;
                }
                field(postedDateTime; Rec."Posted At")
                {
                    Caption = 'Posted date time';
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
}
