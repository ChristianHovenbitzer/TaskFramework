namespace Techdays.TaskFramework.Impl.Vouchers;

using Microsoft.Sales.Customer;

// HANDS-ON: Define the Voucher Journal Line table.
// This is the staging table — lines are validated, then posted to ledger entries.
// TODO: Add fields:
//   1. "Line No." (Integer, PK)
//   2. "Voucher No." (Code[20])
//   3. "Customer No." (Code[20], TableRelation = Customer."No.")
//   4. Amount (Decimal)
//   5. "Posting Date" (Date)
//   6. Description (Text[100])
//   7. "Document No." (Code[20])
// Key: PK on "Line No." with Clustered = true, SumIndexFields = Amount
table 60010 "Voucher Journal Line"
{
    Caption = 'Voucher Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer) { Caption = 'Line No.'; }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}
