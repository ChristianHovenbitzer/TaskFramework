// HANDS-ON: Define the Voucher Ledger Entry table.
// Posted entries land here — one per journal line.
// TODO: Add fields:
//   1. "Entry No." (Integer, PK)
//   2. "Voucher No." (Code[20])
//   3. "Customer No." (Code[20])
//   4. Amount (Decimal)
//   5. "Posting Date" (Date)
//   6. Description (Text[100])
//   7. "Document No." (Code[20])
//   8. "Register No." (Integer)
// Keys: PK on "Entry No.", secondary on "Register No."
table 60011 "Voucher Ledger Entry"
{
    Caption = 'Voucher Ledger Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "Voucher Ledger Entries";
    LookupPageId = "Voucher Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; }
        field(2; "Voucher No."; Code[20]) { Caption = 'Voucher No.'; }
        field(3; "Customer No."; Code[20]) { Caption = 'Customer No.'; }
        field(4; Amount; Decimal) { Caption = 'Amount'; }
        field(5; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(6; Description; Text[100]) { Caption = 'Description'; }
        field(7; "Document No."; Code[20]) { Caption = 'Document No.'; }
        field(8; "Register No."; Integer) { Caption = 'Register No.'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Register; "Register No.") { }
    }
}
