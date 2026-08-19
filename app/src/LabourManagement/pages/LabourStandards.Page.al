namespace WarehouseAdvanced.LabourManagement;

page 50351 "WHA Labour Standards"
{
    PageType = List;
    ApplicationArea = WHALabourManagement;
    UsageCategory = Lists;
    SourceTable = "WHA Labour Standard";
    Caption = 'Labour standards';

    layout
    {
        area(Content)
        {
            repeater(Standards)
            {
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Task Type"; Rec."Task Type")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Basis; Rec.Basis)
                {
                }
                field("Minutes Per Job"; Rec."Minutes Per Job")
                {
                }
                field("Minutes Per Unit"; Rec."Minutes Per Unit")
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
            }
            group(Explanation)
            {
                Caption = 'About the selected standard';

                field(BasisDescription; BasisDescription)
                {
                    Caption = 'How the expected time is worked out';
                    ToolTip = 'Specifies which of the standard''s numbers are used when work is measured against it.';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescribeBasis();
    end;

    var
        BasisDescription: Text;

    local procedure DescribeBasis()
    var
        LabourMgt: Codeunit "WHA Labour Mgt.";
    begin
        BasisDescription := LabourMgt.DescribeBasis(Rec);
    end;
}
