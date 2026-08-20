namespace WarehouseAdvanced.Counting;

report 50510 "WHA Count Sheet Print"
{
    Caption = 'Count sheet';
    ApplicationArea = WHACounting;
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './layout/Counting/CountSheetPrint.rdlc';
    AdditionalSearchTerms = 'count sheet, stocktake, physical inventory, blind count';

    dataset
    {
        dataitem(CountSheet; "WHA Count Sheet")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Location Code", Status, "Assigned To User ID";

            column(No_CountSheet; CountSheet."No.")
            {
                IncludeCaption = true;
            }
            column(Description_CountSheet; CountSheet.Description)
            {
                IncludeCaption = true;
            }
            column(LocationCode_CountSheet; CountSheet."Location Code")
            {
                IncludeCaption = true;
            }
            column(Status_CountSheet; CountSheet.Status)
            {
                IncludeCaption = true;
            }
            column(Blind_CountSheet; CountSheet.Blind)
            {
                IncludeCaption = true;
            }
            column(DueDate_CountSheet; CountSheet."Due Date")
            {
                IncludeCaption = true;
            }
            column(AssignedToUserID_CountSheet; CountSheet."Assigned To User ID")
            {
                IncludeCaption = true;
            }

            dataitem(CountSheetLine; "WHA Count Sheet Line")
            {
                DataItemLink = "Sheet No." = field("No.");
                DataItemTableView = sorting("Sheet No.", "Line No.");

                column(LineNo_CountSheetLine; CountSheetLine."Line No.")
                {
                    IncludeCaption = true;
                }
                column(BinCode_CountSheetLine; CountSheetLine."Bin Code")
                {
                    IncludeCaption = true;
                }
                column(ItemNo_CountSheetLine; CountSheetLine."Item No.")
                {
                    IncludeCaption = true;
                }
                column(Description_CountSheetLine; CountSheetLine.Description)
                {
                    IncludeCaption = true;
                }
                column(VariantCode_CountSheetLine; CountSheetLine."Variant Code")
                {
                    IncludeCaption = true;
                }
                column(UnitOfMeasureCode_CountSheetLine; CountSheetLine."Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(LotNo_CountSheetLine; CountSheetLine."Lot No.")
                {
                    IncludeCaption = true;
                }
                column(SerialNo_CountSheetLine; CountSheetLine."Serial No.")
                {
                    IncludeCaption = true;
                }
                column(HandlingUnitNo_CountSheetLine; CountSheetLine."Handling Unit No.")
                {
                    IncludeCaption = true;
                }
                column(ExpectedQuantity_CountSheetLine; ExpectedQuantityToShow)
                {
                }
                column(CountedQuantity_CountSheetLine; CountSheetLine."Counted Quantity")
                {
                    IncludeCaption = true;
                }
                column(Counted_CountSheetLine; CountSheetLine.Counted)
                {
                    IncludeCaption = true;
                }
                column(Variance_CountSheetLine; CountSheetLine.Variance)
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                var
                    CountSheetLogic: Codeunit "WHA Count Sheet Logic";
                begin
                    ExpectedQuantityToShow := CountSheetLogic.ExpectedQuantityToPrint(CountSheet, CountSheetLine);
                end;
            }
        }
    }

    labels
    {
        ReportCaptionLbl = 'Count sheet';
        PageCaptionLbl = 'Page';
        ExpectedQuantityLbl = 'Expected quantity';
        BlindCountLbl = 'Blind count — the expected quantity is deliberately not shown';
        CountedByLbl = 'Counted by';
        CountedOnLbl = 'Counted on';
    }

    var
        ExpectedQuantityToShow: Decimal;
}
