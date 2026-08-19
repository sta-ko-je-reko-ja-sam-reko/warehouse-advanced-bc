namespace WarehouseAdvanced.Analytics;

page 50703 "WHA API KPI Snapshot"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'analytics';
    APIVersion = 'v1.0';
    EntityName = 'kpiSnapshot';
    EntitySetName = 'kpiSnapshots';
    EntityCaption = 'KPI snapshot';
    EntitySetCaption = 'KPI snapshots';
    SourceTable = "WHA KPI Snapshot";
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
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                }
                field(measure; Rec.Measure)
                {
                    Caption = 'Measure';
                }
                field(value; Rec.Value)
                {
                    Caption = 'Value';
                }
                field(measuredIn; Rec."Measured In")
                {
                    Caption = 'Measured in';
                }
                field(fromDate; Rec."From Date")
                {
                    Caption = 'From date';
                }
                field(toDate; Rec."To Date")
                {
                    Caption = 'To date';
                }
                field(capturedDateTime; Rec."Captured At")
                {
                    Caption = 'Captured date time';
                }
                field(capturedByUserId; Rec."Captured By User ID")
                {
                    Caption = 'Captured by user ID';
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
