namespace WarehouseAdvanced.HandlingUnit;

report 50057 "WHA Handling Unit Contents"
{
    Caption = 'Handling unit contents';
    ApplicationArea = WHAHandlingUnits;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'pallet contents, packing list, pallet label';

    dataset
    {
        dataitem(HandlingUnit; "WHA Handling Unit")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Location Code", "Bin Code", Status;

            column(No_HandlingUnit; HandlingUnit."No.")
            {
                IncludeCaption = true;
            }
            column(SSCC_HandlingUnit; HandlingUnit.SSCC)
            {
                IncludeCaption = true;
            }
            column(Description_HandlingUnit; HandlingUnit.Description)
            {
                IncludeCaption = true;
            }
            column(LocationCode_HandlingUnit; HandlingUnit."Location Code")
            {
                IncludeCaption = true;
            }
            column(BinCode_HandlingUnit; HandlingUnit."Bin Code")
            {
                IncludeCaption = true;
            }
            column(Status_HandlingUnit; HandlingUnit.Status)
            {
                IncludeCaption = true;
            }
            column(ParentNo_HandlingUnit; HandlingUnit."Parent No.")
            {
                IncludeCaption = true;
            }

            dataitem(HandlingUnitLine; "WHA Handling Unit Line")
            {
                DataItemLink = "Handling Unit No." = field("No.");
                DataItemTableView = sorting("Handling Unit No.", "Line No.");

                column(LineNo_HandlingUnitLine; HandlingUnitLine."Line No.")
                {
                    IncludeCaption = true;
                }
                column(ItemNo_HandlingUnitLine; HandlingUnitLine."Item No.")
                {
                    IncludeCaption = true;
                }
                column(Description_HandlingUnitLine; HandlingUnitLine.Description)
                {
                    IncludeCaption = true;
                }
                column(VariantCode_HandlingUnitLine; HandlingUnitLine."Variant Code")
                {
                    IncludeCaption = true;
                }
                column(Quantity_HandlingUnitLine; HandlingUnitLine.Quantity)
                {
                    IncludeCaption = true;
                }
                column(UnitOfMeasureCode_HandlingUnitLine; HandlingUnitLine."Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(LotNo_HandlingUnitLine; HandlingUnitLine."Lot No.")
                {
                    IncludeCaption = true;
                }
                column(SerialNo_HandlingUnitLine; HandlingUnitLine."Serial No.")
                {
                    IncludeCaption = true;
                }
            }
        }
    }

    labels
    {
        ReportCaptionLbl = 'Handling unit contents';
        PageCaptionLbl = 'Page';
        PrintedAtLbl = 'Printed';
        TotalLinesLbl = 'Lines on this unit';
    }
}
