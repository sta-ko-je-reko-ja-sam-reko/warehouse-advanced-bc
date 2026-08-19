namespace WarehouseAdvanced.Integration;

table 50651 "WHA Integration Message"
{
    Caption = 'Integration message';
    DataClassification = CustomerContent;
    LookupPageId = "WHA Integration Messages";
    DrillDownPageId = "WHA Integration Messages";
    DataCaptionFields = "Entry No.", "Message Type";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry no.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number that identifies the message.';
            AutoIncrement = true;
        }
        field(2; Direction; Enum "WHA Int. Direction")
        {
            Caption = 'Direction';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the message came from the partner system or is waiting to be collected by it.';
        }
        field(3; "Message Type"; Enum "WHA Int. Message Type")
        {
            Caption = 'Message type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what the message is about. The type decides which code applies it.';
        }
        field(10; "Partner System"; Code[20])
        {
            Caption = 'Partner system';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the system the message was received from or is waiting for.';
        }
        field(11; "External Id"; Code[50])
        {
            Caption = 'External ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the partner system identifies what this message is about. It is what stops the same thing being sent or applied twice.';
        }
        field(12; "Correlation Id"; Code[50])
        {
            Caption = 'Correlation ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the identifier that ties an answer back to the message that asked for it.';
        }
        field(20; Status; Enum "WHA Int. Message Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how far the message has got. A new inbound message is waiting to be applied; a new outbound message is waiting to be collected.';
            Editable = false;
        }
        field(21; "Error Message"; Text[250])
        {
            Caption = 'Error message';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies why the message could not be applied.';
            Editable = false;
        }
        field(22; "Retry Count"; Integer)
        {
            Caption = 'Retry count';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many times applying the message has been tried.';
            Editable = false;
        }
        field(30; Payload; Blob)
        {
            Caption = 'Payload';
            DataClassification = CustomerContent;
        }
        field(40; "Received At"; DateTime)
        {
            Caption = 'Received at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the message arrived, or when it was put in the outbox.';
            Editable = false;
        }
        field(41; "Processed At"; DateTime)
        {
            Caption = 'Processed at';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies when the message was applied, or when the partner system confirmed it had collected it.';
            Editable = false;
        }
        field(50; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the record the message created, changed, or was built from.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Queue; Direction, Status, "Message Type")
        {
        }
        key(External; "Message Type", "External Id")
        {
        }
        key(Correlation; "Correlation Id")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Message Type", Status)
        {
        }
        fieldgroup(Brick; "Entry No.", Direction, "Message Type", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        Logic().Trigger_OnInsert(Rec);
    end;

    trigger OnDelete()
    begin
        Logic().Trigger_OnDelete(Rec);
    end;

    var
        ILogic: Interface "WHA IIntegrationMessage";
        ILogicDefined: Boolean;

    /// <summary>
    /// Inject an alternative implementation of the integration message logic. Used by tests to supply a
    /// fake and by dependent extensions to substitute their own behaviour.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure Define(Implementation: Interface "WHA IIntegrationMessage")
    begin
        ILogic := Implementation;
        ILogicDefined := true;
    end;

    local procedure Logic(): Interface "WHA IIntegrationMessage"
    var
        DefaultLogic: Codeunit "WHA Integration Msg. Logic";
    begin
        if not ILogicDefined then
            Define(DefaultLogic);
        exit(ILogic);
    end;
}
