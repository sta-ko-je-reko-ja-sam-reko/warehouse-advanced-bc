namespace WarehouseAdvanced.Slotting;

using WarehouseAdvanced.Core;

page 50304 "WHA API Slotting Proposal"
{
    PageType = API;
    APIPublisher = 'matr';
    APIGroup = 'slotting';
    APIVersion = 'v1.0';
    EntityName = 'slottingProposal';
    EntitySetName = 'slottingProposals';
    EntityCaption = 'Slotting proposal';
    EntitySetCaption = 'Slotting proposals';
    SourceTable = "WHA Slotting Proposal";
    Extensible = false;
    InsertAllowed = false;
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
                    Editable = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location code';
                    Editable = false;
                }
                field(itemNumber; Rec."Item No.")
                {
                    Caption = 'Item number';
                    Editable = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant code';
                    Editable = false;
                }
                field(velocityClass; Rec.Class)
                {
                    Caption = 'Class';
                    Editable = false;
                }
                field(fromBinCode; Rec."From Bin Code")
                {
                    Caption = 'From bin code';
                    Editable = false;
                }
                field(fromBinRanking; Rec."From Bin Ranking")
                {
                    Caption = 'From bin ranking';
                    Editable = false;
                }
                field(requiredBinRanking; Rec."Required Bin Ranking")
                {
                    Caption = 'Required bin ranking';
                    Editable = false;
                }
                field(toBinCode; Rec."To Bin Code")
                {
                    Caption = 'To bin code';
                }
                field(reason; Rec.Reason)
                {
                    Caption = 'Reason';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(taskNumber; Rec."Task No.")
                {
                    Caption = 'Task number';
                    Editable = false;
                }
                field(handledByUserId; Rec."Handled By User ID")
                {
                    Caption = 'Handled by user ID';
                    Editable = false;
                }
                field(handledDateTime; Rec."Handled At")
                {
                    Caption = 'Handled date time';
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

    trigger OnModifyRecord(): Boolean
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHASlotting);
        exit(true);
    end;

    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
}
