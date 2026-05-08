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
            // (Not in scope for the workshop — left here as a code smell to discuss.)
        }
        field(5; "Execution Interval (Seconds)"; Integer)
        {
            Caption = 'Execution Interval (Seconds)';
            MinValue = 0;
        }
        field(6; "Last Processed At"; DateTime) { Caption = 'Last Processed At'; }
        field(7; "Default Verbosity"; Enum "Task Verbosity") { Caption = 'Default Verbosity'; }
        field(8; "Default Error Handler"; Enum "Task Error Handler") { Caption = 'Default Error Handler'; }
        field(9; "Enable Batches"; Boolean) { Caption = 'Enable Batches'; }
        field(10; "Batch Size"; Integer) { Caption = 'Batch Size'; MinValue = 1; }
        field(11; "Archive Enabled"; Boolean) { Caption = 'Archive Enabled'; }

        // TODO: (Step 2 - Separation of Concerns): add the Retention Days field used by
        // ProcessLogRetention so it's no longer hardcoded.
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
