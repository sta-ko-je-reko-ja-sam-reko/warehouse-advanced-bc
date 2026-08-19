namespace WarehouseAdvanced.DockYard;

page 50455 "WHA API Dock Door"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'dockYard';
    APIVersion = 'v1.0';
    EntityName = 'dockDoor';
    EntitySetName = 'dockDoors';
    EntityCaption = 'Dock door';
    EntitySetCaption = 'Dock doors';
    SourceTable = "WHA Dock Door";
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
                field(doorCode; Rec."Code")
                {
                    Caption = 'Door code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(direction; Rec.Direction)
                {
                    Caption = 'Direction';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
                }
                field(waitingPositionCode; Rec."Yard Position Code")
                {
                    Caption = 'Waiting position code';
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
