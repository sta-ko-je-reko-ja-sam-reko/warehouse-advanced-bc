namespace WarehouseAdvanced.Packing;

page 50406 "WHA API Pack Session"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'packing';
    APIVersion = 'v1.0';
    EntityName = 'packSession';
    EntitySetName = 'packSessions';
    EntityCaption = 'Packing session';
    EntitySetCaption = 'Packing sessions';
    SourceTable = "WHA Pack Session";
    Extensible = false;
    Editable = false;
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
                field(stationCode; Rec."Station Code")
                {
                    Caption = 'Station code';
                }
                field(handlingUnitNumber; Rec."Handling Unit No.")
                {
                    Caption = 'Handling unit number';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(packedByUserId; Rec."Packed By User ID")
                {
                    Caption = 'Packed by user ID';
                }
                field(verifiedByUserId; Rec."Verified By User ID")
                {
                    Caption = 'Verified by user ID';
                }
                field(startedDateTime; Rec."Started At")
                {
                    Caption = 'Started date time';
                }
                field(closedDateTime; Rec."Closed At")
                {
                    Caption = 'Closed date time';
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
