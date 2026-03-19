namespace Techdays.TaskFramework.Core.Errors;

table 50002 "Task Error Log"
{
    Caption = 'Task Error Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Task Entry No."; Integer) { Caption = 'Task Entry No.'; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Error Message"; Text[250]) { Caption = 'Error Message'; }
        field(4; "Created At"; DateTime) { Caption = 'Created At'; }
    }

    keys
    {
        key(PK; "Task Entry No.", "Line No.") { Clustered = true; }
    }
}
