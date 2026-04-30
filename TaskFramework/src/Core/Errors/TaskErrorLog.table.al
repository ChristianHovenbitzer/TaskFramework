table 50002 "Task Error Log"
{
    Caption = 'Task Error Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Task Entry No."; Integer) { Caption = 'Task Entry No.'; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Task Type"; Enum "Task Processing Type") { Caption = 'Task Type'; }
        field(4; "Error Message"; Text[2048]) { Caption = 'Error Message'; }
        field(5; "Error Detail"; Text[2048]) { Caption = 'Error Detail'; }
        field(6; "Created At"; DateTime) { Caption = 'Created At'; }
        field(7; "Is Blocking"; Boolean) { Caption = 'Is Blocking'; }
        field(8; Source; Text[250]) { Caption = 'Source'; }
        field(9; "Correlation Id"; Guid) { Caption = 'Correlation Id'; }
    }

    keys
    {
        key(PK; "Task Entry No.", "Line No.") { Clustered = true; }
    }
}
