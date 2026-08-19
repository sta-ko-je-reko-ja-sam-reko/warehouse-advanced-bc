namespace WarehouseAdvanced.DockYard;

page 50456 "WHA API Yard Position"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'dockYard';
    APIVersion = 'v1.0';
    EntityName = 'yardPosition';
    EntitySetName = 'yardPositions';
    EntityCaption = 'Yard position';
    EntitySetCaption = 'Yard positions';
    SourceTable = "WHA Yard Position";
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
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(positionCode; Rec."Code")
                {
                    Caption = 'Position code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(occupiedByAppointmentNumber; Rec."Occupied By Appt. No.")
                {
                    Caption = 'Occupied by appointment number';
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
