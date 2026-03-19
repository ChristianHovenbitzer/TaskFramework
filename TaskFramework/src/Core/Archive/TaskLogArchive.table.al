namespace Techdays.TaskFramework.Core.Archive;

using Microsoft.CRM.Task;

table 50001 "Task Log Archive"
{
    Caption = 'Task Log Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; }
        field(2; "Task Type"; Enum "Task Type") { Caption = 'Task Type'; }
        field(3; Status; Enum "Task Status") { Caption = 'Status'; }
        field(4; Description; Text[100]) { Caption = 'Description'; }
        field(5; Payload; Blob) { Caption = 'Payload'; }
        field(6; "Created At"; DateTime) { Caption = 'Created At'; }
        field(7; "Processing Started At"; DateTime) { Caption = 'Processing Started At'; }
        field(8; "Processing Completed At"; DateTime) { Caption = 'Processing Completed At'; }
        field(9; "Last Error Message"; Text[250]) { Caption = 'Last Error Message'; }
        field(10; "Retry Count"; Integer) { Caption = 'Retry Count'; }
        field(100; "Archived At"; DateTime) { Caption = 'Archived At'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ArchivedAtKey; "Archived At") { }
    }
}
