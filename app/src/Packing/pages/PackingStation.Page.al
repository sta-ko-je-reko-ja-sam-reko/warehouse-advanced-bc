namespace WarehouseAdvanced.Packing;

using Microsoft.Inventory.Item;
using WarehouseAdvanced.HandlingUnit;

page 50403 "WHA Packing Station"
{
    PageType = Card;
    ApplicationArea = WHAPacking;
    UsageCategory = Tasks;
    SourceTable = "WHA Pack Session";
    Caption = 'Packing station';
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    AdditionalSearchTerms = 'pack, carton, box, pack bench, packing';

    layout
    {
        area(Content)
        {
            group(Bench)
            {
                Caption = 'Bench';

                field(StationCode; StationCode)
                {
                    Caption = 'Station';
                    ToolTip = 'Specifies the bench you are packing at.';
                    TableRelation = "WHA Pack Station".Code;
                    Editable = true;
                }
            }
            group(Carton)
            {
                Caption = 'Carton';
                Visible = HasCarton;

                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Handling Unit No."; Rec."Handling Unit No.")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Line Count"; Rec."Line Count")
                {
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                }
            }
            group(Add)
            {
                Caption = 'Put in the carton';
                Visible = CanPack;

                field(PackItemNo; PackItemNo)
                {
                    Caption = 'Item no.';
                    ToolTip = 'Specifies what is going into the carton.';
                    TableRelation = Item."No.";
                    Editable = true;
                }
                field(PackVariantCode; PackVariantCode)
                {
                    Caption = 'Variant code';
                    ToolTip = 'Specifies which variant is going in, if the item has any.';
                    Editable = true;
                }
                field(PackQuantity; PackQuantity)
                {
                    Caption = 'Quantity';
                    ToolTip = 'Specifies how much is going in.';
                    DecimalPlaces = 0 : 5;
                    MinValue = 0;
                    Editable = true;
                }
            }
            part(Contents; "WHA Handling Unit Lines")
            {
                Caption = 'What is in the carton';
                SubPageLink = "Handling Unit No." = field("Handling Unit No.");
                Visible = HasCarton;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StartCarton)
            {
                Caption = 'New carton';
                ToolTip = 'Specifies the action that opens a new carton at this bench and starts packing into it.';
                Image = NewItem;
                Enabled = not CanPack;

                trigger OnAction()
                begin
                    ApplyStart();
                end;
            }
            action(PackLine)
            {
                Caption = 'Put in';
                ToolTip = 'Specifies the action that puts what you entered above into the carton.';
                Image = Add;
                Enabled = CanPack;

                trigger OnAction()
                begin
                    ApplyPack();
                end;
            }
            action(VerifyCarton)
            {
                Caption = 'Check';
                ToolTip = 'Specifies the action that records that you have checked what is in the carton.';
                Image = Confirm;
                Enabled = CanPack;

                trigger OnAction()
                begin
                    PackLogic.Verify(Rec);
                    Refresh();
                end;
            }
            action(CloseCarton)
            {
                Caption = 'Close carton';
                ToolTip = 'Specifies the action that finishes the carton. Nothing more can be put into it afterwards.';
                Image = Approve;
                Enabled = HasCarton;

                trigger OnAction()
                begin
                    PackLogic.Close(Rec);
                    Refresh();
                end;
            }
            action(CancelCarton)
            {
                Caption = 'Abandon';
                ToolTip = 'Specifies the action that stops packing this carton. Whatever is already in it stays there.';
                Image = Cancel;
                Enabled = HasCarton;

                trigger OnAction()
                begin
                    PackLogic.Cancel(Rec);
                    Refresh();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(StartCartonRef; StartCarton)
                {
                }
                actionref(PackLineRef; PackLine)
                {
                }
                actionref(VerifyCartonRef; VerifyCarton)
                {
                }
                actionref(CloseCartonRef; CloseCarton)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SuggestStation();
        Refresh();
    end;

    var
        PackLogic: Codeunit "WHA Pack Session Logic";
        StationCode: Code[20];
        PackItemNo: Code[20];
        PackVariantCode: Code[10];
        PackQuantity: Decimal;
        HasCarton: Boolean;
        CanPack: Boolean;

    local procedure SuggestStation()
    var
        Setup: Record "WHA Pack Setup";
        PackFeatureSetup: Codeunit "WHA Pack Feature Setup";
    begin
        PackFeatureSetup.EnsureSetup(Setup);
        StationCode := Setup."Default Station Code";
    end;

    local procedure ApplyStart()
    begin
        PackLogic.Start(Rec, StationCode);
        ClearEntry();
        Refresh();
    end;

    local procedure ApplyPack()
    begin
        PackLogic.PackItem(Rec, PackItemNo, PackVariantCode, PackQuantity);
        ClearEntry();
        Refresh();
    end;

    local procedure ClearEntry()
    begin
        PackItemNo := '';
        PackVariantCode := '';
        PackQuantity := 0;
    end;

    local procedure Refresh()
    begin
        HasCarton := Rec."Entry No." <> 0;
        CanPack := HasCarton and (Rec.Status = Rec.Status::WHAPacking);
        CurrPage.Update(false);
    end;
}
