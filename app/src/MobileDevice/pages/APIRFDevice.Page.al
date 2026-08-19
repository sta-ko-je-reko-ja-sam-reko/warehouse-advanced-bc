namespace WarehouseAdvanced.MobileDevice;

using WarehouseAdvanced.Core;

page 50104 "WHA API RF Device"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'mobileDevice';
    APIVersion = 'v1.0';
    EntityName = 'handheldDevice';
    EntitySetName = 'handheldDevices';
    EntityCaption = 'Handheld device';
    EntitySetCaption = 'Handheld devices';
    SourceTable = "WHA RF Device";
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
                field(defaultLocationCode; Rec."Default Location Code")
                {
                    Caption = 'Default location code';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(lastUserId; Rec."Last User ID")
                {
                    Caption = 'Last user ID';
                    Editable = false;
                }
                field(lastSeenDateTime; Rec."Last Seen At")
                {
                    Caption = 'Last seen date time';
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAMobileDevice);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAMobileDevice);
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHAMobileDevice);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
