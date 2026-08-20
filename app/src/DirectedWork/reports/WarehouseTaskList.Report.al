namespace WarehouseAdvanced.DirectedWork;

report 50218 "WHA Warehouse Task List"
{
    Caption = 'Warehouse task list';
    ApplicationArea = WHADirectedWork;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'pick list, put-away list, work list, job list';

    dataset
    {
        dataitem(WarehouseTask; "WHA Warehouse Task")
        {
            DataItemTableView = sorting(Priority, "Due Date", "No.");
            RequestFilterFields = "Location Code", Status, "Task Type", "Assigned To User ID", "Due Date";

            column(No_WarehouseTask; WarehouseTask."No.")
            {
                IncludeCaption = true;
            }
            column(TaskType_WarehouseTask; WarehouseTask."Task Type")
            {
                IncludeCaption = true;
            }
            column(Description_WarehouseTask; WarehouseTask.Description)
            {
                IncludeCaption = true;
            }
            column(Status_WarehouseTask; WarehouseTask.Status)
            {
                IncludeCaption = true;
            }
            column(Priority_WarehouseTask; WarehouseTask.Priority)
            {
                IncludeCaption = true;
            }
            column(DueDate_WarehouseTask; WarehouseTask."Due Date")
            {
                IncludeCaption = true;
            }
            column(LocationCode_WarehouseTask; WarehouseTask."Location Code")
            {
                IncludeCaption = true;
            }
            column(FromBinCode_WarehouseTask; WarehouseTask."From Bin Code")
            {
                IncludeCaption = true;
            }
            column(ToBinCode_WarehouseTask; WarehouseTask."To Bin Code")
            {
                IncludeCaption = true;
            }
            column(HandlingUnitNo_WarehouseTask; WarehouseTask."Handling Unit No.")
            {
                IncludeCaption = true;
            }
            column(ItemNo_WarehouseTask; WarehouseTask."Item No.")
            {
                IncludeCaption = true;
            }
            column(VariantCode_WarehouseTask; WarehouseTask."Variant Code")
            {
                IncludeCaption = true;
            }
            column(Quantity_WarehouseTask; WarehouseTask.Quantity)
            {
                IncludeCaption = true;
            }
            column(UnitOfMeasureCode_WarehouseTask; WarehouseTask."Unit of Measure Code")
            {
                IncludeCaption = true;
            }
            column(QuantityHandled_WarehouseTask; WarehouseTask."Quantity Handled")
            {
                IncludeCaption = true;
            }
            column(LotNo_WarehouseTask; WarehouseTask."Lot No.")
            {
                IncludeCaption = true;
            }
            column(SerialNo_WarehouseTask; WarehouseTask."Serial No.")
            {
                IncludeCaption = true;
            }
            column(AssignedToUserID_WarehouseTask; WarehouseTask."Assigned To User ID")
            {
                IncludeCaption = true;
            }
            column(WaveNo_WarehouseTask; WarehouseTask."Wave No.")
            {
                IncludeCaption = true;
            }
            column(SourceNo_WarehouseTask; WarehouseTask."Source No.")
            {
                IncludeCaption = true;
            }
        }
    }

    labels
    {
        ReportCaptionLbl = 'Warehouse task list';
        PageCaptionLbl = 'Page';
        SignedForLbl = 'Signed for by';
        CompletedLbl = 'Done';
    }
}
