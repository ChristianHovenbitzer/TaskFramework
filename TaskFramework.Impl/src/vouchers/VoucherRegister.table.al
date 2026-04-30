// HANDS-ON: Define the Voucher Register table.
// Groups posted ledger entries by batch — tracks From/To Entry No.
// TODO: Add fields:
//   1. "No." (Integer, PK)
//   2. "From Entry No." (Integer)
//   3. "To Entry No." (Integer)
//   4. "Creation Date" (Date)
//   5. "Source Code" (Code[10])
//   6. "User ID" (Code[50])
table 60012 "Voucher Register"
{
    Caption = 'Voucher Register';
    DataClassification = CustomerContent;
    DrillDownPageId = "Voucher Registers";
    LookupPageId = "Voucher Registers";

    fields
    {
        field(1; "No."; Integer) { Caption = 'No.'; }
        field(2; "From Entry No."; Integer) { Caption = 'From Entry No.'; }
        field(3; "To Entry No."; Integer) { Caption = 'To Entry No.'; }
        field(4; "Creation Date"; Date) { Caption = 'Creation Date'; }
        field(5; "Source Code"; Code[10]) { Caption = 'Source Code'; }
        field(6; "User ID"; Code[50]) { Caption = 'User ID'; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
