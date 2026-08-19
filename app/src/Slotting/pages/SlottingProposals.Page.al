namespace WarehouseAdvanced.Slotting;

page 50302 "WHA Slotting Proposals"
{
    PageType = List;
    ApplicationArea = WHASlotting;
    UsageCategory = Tasks;
    SourceTable = "WHA Slotting Proposal";
    Caption = 'Slotting proposals';
    InsertAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Proposals)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field(Class; Rec.Class)
                {
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                }
                field("From Bin Ranking"; Rec."From Bin Ranking")
                {
                }
                field("Required Bin Ranking"; Rec."Required Bin Ranking")
                {
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                }
                field(Reason; Rec.Reason)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Task No."; Rec."Task No.")
                {
                }
                field("Handled By User ID"; Rec."Handled By User ID")
                {
                }
                field("Handled At"; Rec."Handled At")
                {
                }
                field("Created At"; Rec."Created At")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AcceptProposal)
            {
                Caption = 'Accept';
                ToolTip = 'Specifies the action that accepts the proposal. Fill in where the goods should go first and the work to move them is raised for you.';
                Image = Approve;

                trigger OnAction()
                begin
                    ApplyAccept();
                end;
            }
            action(RejectProposal)
            {
                Caption = 'Reject';
                ToolTip = 'Specifies the action that turns the proposal down. It is kept, because what was suggested and refused is worth knowing.';
                Image = Reject;

                trigger OnAction()
                begin
                    ApplyReject();
                end;
            }
            action(RaiseMovement)
            {
                Caption = 'Raise the move';
                ToolTip = 'Specifies the action that raises the work for a proposal that was accepted before anybody had decided where the goods should go.';
                Image = CreateMovement;

                trigger OnAction()
                begin
                    ApplyRaiseWork();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AcceptProposalRef; AcceptProposal)
                {
                }
                actionref(RejectProposalRef; RejectProposal)
                {
                }
            }
        }
    }

    var
        AcceptedWithWorkMsg: Label 'Accepted, and warehouse job %1 was raised to make the move.', Comment = '%1 = the number of the warehouse task that was created';
        AcceptedMsg: Label 'Accepted. Nothing was raised, because the proposal does not say where the goods should go.';
        RaisedMsg: Label 'Warehouse job %1 was raised to make the move.', Comment = '%1 = the number of the warehouse task that was created';

    local procedure ApplyAccept()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
        TaskNo: Code[20];
    begin
        TaskNo := SlottingMgt.Accept(Rec);
        if TaskNo <> '' then
            Message(AcceptedWithWorkMsg, TaskNo)
        else
            Message(AcceptedMsg);
        CurrPage.Update(false);
    end;

    local procedure ApplyReject()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        SlottingMgt.Reject(Rec);
        CurrPage.Update(false);
    end;

    local procedure ApplyRaiseWork()
    var
        SlottingMgt: Codeunit "WHA Slotting Mgt.";
    begin
        Message(RaisedMsg, SlottingMgt.RaiseWork(Rec));
        CurrPage.Update(false);
    end;
}
