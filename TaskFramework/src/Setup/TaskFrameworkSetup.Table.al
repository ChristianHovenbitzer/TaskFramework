namespace Techdays.TaskFramework.Setup;

table 50003 "Task Framework Setup"
{
    Caption = 'Task Framework Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Primary Key'; }
        field(2; Enabled; Boolean) { Caption = 'Enabled'; }
        field(3; "Max Retry Count"; Integer) { Caption = 'Max Retry Count'; InitValue = 3; }
        field(4; "Default G/L Account"; Code[20])
        {
            Caption = 'Default G/L Account';
            // ANTI-PATTERN: One hardcoded G/L field instead of proper account mapping per entry type.
            // TODO Step 2: Replace with proper voucher account mapping fields
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
