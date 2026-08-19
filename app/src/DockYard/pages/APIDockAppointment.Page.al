namespace WarehouseAdvanced.DockYard;

using WarehouseAdvanced.Core;

page 50457 "WHA API Dock Appointment"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'dockYard';
    APIVersion = 'v1.0';
    EntityName = 'dockAppointment';
    EntitySetName = 'dockAppointments';
    EntityCaption = 'Dock appointment';
    EntitySetCaption = 'Dock appointments';
    SourceTable = "WHA Dock Appointment";
    DelayedInsert = true;
    Extensible = false;
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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                    Editable = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(direction; Rec.Direction)
                {
                    Caption = 'Direction';
                }
                field(doorCode; Rec."Dock Door Code")
                {
                    Caption = 'Door code';
                }
                field(carrierName; Rec."Carrier Name")
                {
                    Caption = 'Carrier name';
                }
                field(trailerNumber; Rec."Trailer No.")
                {
                    Caption = 'Trailer number';
                }
                field(reference; Rec.Reference)
                {
                    Caption = 'Reference';
                }
                field(expectedDateTime; Rec."Expected At")
                {
                    Caption = 'Expected date time';
                }
                field(slotMinutes; Rec."Slot Minutes")
                {
                    Caption = 'Slot minutes';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(yardPositionCode; Rec."Yard Position Code")
                {
                    Caption = 'Yard position code';
                    Editable = false;
                }
                field(arrivedDateTime; Rec."Arrived At")
                {
                    Caption = 'Arrived date time';
                    Editable = false;
                }
                field(atDoorDateTime; Rec."At Door At")
                {
                    Caption = 'At door date time';
                    Editable = false;
                }
                field(departedDateTime; Rec."Departed At")
                {
                    Caption = 'Departed date time';
                    Editable = false;
                }
                field(bookedByUserId; Rec."Booked By User ID")
                {
                    Caption = 'Booked by user ID';
                    Editable = false;
                }
                field(createdDateTime; Rec."Created At")
                {
                    Caption = 'Created date time';
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
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADockYard);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADockYard);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
