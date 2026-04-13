namespace Techdays.TaskFramework.Impl.Vouchers;

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
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
