namespace WarehouseAdvanced.MobileDevice;

using Microsoft.Inventory.Location;
using System.Security.AccessControl;

table 50101 "WHA RF Device"
{
    Caption = 'Handheld device';
    DataClassification = CustomerContent;
    LookupPageId = "WHA RF Devices";
    DrillDownPageId = "WHA RF Devices";
    DataCaptionFields = "Code", Description;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code printed on the handheld, which the operator scans to sign in.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which handheld this is, so it can be found when it goes missing.';
        }
        field(10; "Default Location Code"; Code[10])
        {
            Caption = 'Default location code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the location this handheld works at. An operator signed in on it is only offered work at that location. Leave it blank to offer work anywhere.';
            TableRelation = Location;
        }
        field(20; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the handheld is out of use. A blocked device cannot be signed in to.';
        }
        field(30; "Last User ID"; Code[50])
        {
            Caption = 'Last user ID';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies who last signed in on this handheld.';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(31; "Last Seen At"; DateTime)
        {
            Caption = 'Last seen at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when this handheld was last signed in to. It is how a device that has been left in a rack is spotted.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(Placement; "Default Location Code", Blocked)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Default Location Code")
        {
        }
        fieldgroup(Brick; "Code", Description, "Default Location Code", "Last Seen At")
        {
        }
    }
}
