table 50000 "Task Log Entry"
{
    Caption = 'Task Log Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Task Processing Type"; Enum "Task Processing Type") { Caption = 'Task Type'; }
        field(3; Status; Enum "Task Processing Status") { Caption = 'Status'; }
        field(4; Description; Text[100]) { Caption = 'Description'; }
        field(5; Payload; Blob) { Caption = 'Payload'; }
        field(6; "Created At"; DateTime) { Caption = 'Created At'; }
        field(7; "Processing Started At"; DateTime) { Caption = 'Processing Started At'; }
        field(8; "Processing Completed At"; DateTime) { Caption = 'Processing Completed At'; }
        field(9; "Last Error Message"; Text[250]) { Caption = 'Last Error Message'; }
        field(10; "Retry Count"; Integer) { Caption = 'Retry Count'; }
        field(11; "Error Handler"; Enum "Task Error Handler")
        {
            Caption = 'Error Handler';
        }
        field(12; Verbosity; Enum "Task Verbosity") { Caption = 'Verbosity'; }
        field(13; "Correlation Id"; Guid) { Caption = 'Correlation Id'; }
        field(14; "Archive After Processing"; Boolean) { Caption = 'Archive After Processing'; }
        field(15; "Earliest Processing DateTime"; DateTime) { Caption = 'Earliest Processing DateTime'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(StatusKey; Status, "Entry No.") { }
    }

    /// <summary>Returns the Payload BLOB as UTF-8 text.</summary>
    procedure GetPayloadText(): Text
    var
        InStream: InStream;
        PayloadText: Text;
    begin
        Rec.CalcFields(Payload);
        Rec.Payload.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(PayloadText);
        exit(PayloadText);
    end;

    /// <summary>Writes a UTF-8 text value into the Payload BLOB.</summary>
    procedure SetPayloadText(PayloadText: Text)
    var
        OutStream: OutStream;
    begin
        Rec.Payload.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(PayloadText);
    end;
}
