namespace WarehouseAdvanced.Core;

page 50004 "WHA Warehouse Manager RC"
{
    PageType = RoleCenter;
    Caption = 'Warehouse Advanced';

    layout
    {
        area(RoleCenter)
        {
            part(Activities; "WHA Warehouse Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(Setup)
            {
                Caption = 'Setup';
                Image = Setup;

                action(SetupHub)
                {
                    Caption = 'Guided setup';
                    ToolTip = 'Specifies the action that opens the list of features and what each of them still needs.';
                    Image = Administration;
                    ApplicationArea = All;
                    RunObject = page "WHA Setup Hub";
                }
                action(WarehouseSetup)
                {
                    Caption = 'Warehouse Advanced setup';
                    ToolTip = 'Specifies the action that opens the foundation setup.';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "WHA Warehouse Setup";
                }
            }
        }
    }
}
