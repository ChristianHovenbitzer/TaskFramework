namespace Techdays.TaskFramework.Core;

table 50000 "Task Log Entry"
{
    Caption = 'Task Log Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Task Type"; Enum "Task Type") { Caption = 'Task Type'; }
        field(3; Status; Enum "Task Status") { Caption = 'Status'; }
        field(4; Description; Text[100]) { Caption = 'Description'; }
        field(5; Payload; Blob) { Caption = 'Payload'; }
        field(6; "Created At"; DateTime) { Caption = 'Created At'; }
        field(7; "Processing Started At"; DateTime) { Caption = 'Processing Started At'; }
        field(8; "Processing Completed At"; DateTime) { Caption = 'Processing Completed At'; }
        field(9; "Last Error Message"; Text[250]) { Caption = 'Last Error Message'; }
        field(10; "Retry Count"; Integer) { Caption = 'Retry Count'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(StatusKey; Status, "Entry No.") { }
    }
}
