namespace WarehouseAdvanced.DirectedWork;

using Microsoft.Warehouse.Document;
using WarehouseAdvanced.Core;

pageextension 50200 "WHA Whse. Receipt Tasks" extends "Warehouse Receipt"
{
    actions
    {
        addlast(processing)
        {
            action(WHACreateWarehouseTasks)
            {
                Caption = 'Create warehouse tasks';
                ToolTip = 'Specifies the action that puts a put-away on the warehouse task queue for every line on this receipt that is still outstanding. Lines that already carry work are left alone, so running it twice adds only what is missing.';
                Image = CreateWarehousePick;
                ApplicationArea = WHADirectedWork;
                AccessByPermission = tabledata "WHA Warehouse Task" = I;

                trigger OnAction()
                begin
                    RaiseTasks();
                end;
            }
        }
    }

    var
        RaisedMsg: Label '%1 warehouse task(s) raised from this receipt.', Comment = '%1 = how many tasks were raised';
        NothingRaisedMsg: Label 'Every outstanding line on this receipt already carries warehouse work, so nothing was raised.';

    local procedure RaiseTasks()
    var
        FeatureMgt: Codeunit "WHA Feature Mgt.";
        TaskSourceMgt: Codeunit "WHA Task Source Mgt.";
        SourceType: Enum "WHA Task Source";
        Raised: Integer;
    begin
        FeatureMgt.CheckEnabled(Enum::"WHA Feature"::WHADirectedWork);

        Raised := TaskSourceMgt.GenerateFrom(SourceType::WHAWhseReceipt, Rec."No.");
        if Raised = 0 then
            Message(NothingRaisedMsg)
        else
            Message(RaisedMsg, Raised);
    end;
}
