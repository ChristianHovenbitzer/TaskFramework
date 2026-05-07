// ANTI-PATTERN: Staging area and posted records in same table.
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
