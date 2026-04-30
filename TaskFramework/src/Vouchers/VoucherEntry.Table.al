// ANTI-PATTERN: Staging area and posted records in same table.
//
// TODO: (Step 5 - Journal → Posting → Ledger Entry): delete this table entirely
// and split its responsibilities across three tables following the BC standard:
//   - "Voucher Journal Line" (50010) — staging / editable before posting
//   - "Voucher Ledger Entry" (50011) — posted, immutable audit record
//   - "Voucher Register"     (50012) — groups ledger entries by posting run
// Draft records live in the Journal Line; posting moves them to a Ledger Entry
// row inside a Register. Staging and posted data must never share a table.
table 50004 "Voucher Entry"
{
    Caption = 'Voucher Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = 'Entry No.'; AutoIncrement = true; }
        field(2; "Voucher No."; Code[20]) { Caption = 'Voucher No.'; }
        field(3; "Customer No."; Code[20]) { Caption = 'Customer No.'; }
        field(4; Amount; Decimal) { Caption = 'Amount'; }
        field(5; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(6; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Draft,Posted;
            OptionCaption = 'Draft,Posted';
            // ANTI-PATTERN: Option not Enum. Editable even after "posting".
        }
        field(7; Description; Text[100]) { Caption = 'Description'; }
        field(8; "Document No."; Code[20]) { Caption = 'Document No.'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
