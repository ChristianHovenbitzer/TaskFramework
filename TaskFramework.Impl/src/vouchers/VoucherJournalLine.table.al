namespace Techdays.TaskFramework.Impl.Vouchers;

table 60010 "Voucher Journal Line"
{
    Caption = 'Voucher Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer) { Caption = 'Line No.'; }
        field(2; "Voucher No."; Code[20]) { Caption = 'Voucher No.'; }
        field(3; "Customer No."; Code[20]) { Caption = 'Customer No.'; }
        field(4; Amount; Decimal) { Caption = 'Amount'; }
        field(5; "Posting Date"; Date) { Caption = 'Posting Date'; }
        field(6; Description; Text[100]) { Caption = 'Description'; }
        field(7; "Document No."; Code[20]) { Caption = 'Document No.'; }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; SumIndexFields = Amount; }
    }
}
