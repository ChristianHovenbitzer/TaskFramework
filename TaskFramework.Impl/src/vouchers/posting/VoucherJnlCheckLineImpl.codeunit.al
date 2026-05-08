using System.Utilities;

// TODO: (Step 5 - Journal → Posting → Ledger Entry): internal Impl carrying the
// validation logic. Uses TestField so missing-field errors carry the field name.
// Errors get collected (not bail-on-first) when called from PostBatch under
// [ErrorBehavior(Collect)].
codeunit 60010 "Voucher Jnl.-Check Line Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    procedure RunCheck(VoucherJnlLine: Record "Voucher Journal Line")
    begin
        VoucherJnlLine.TestField("Customer No.");
        VoucherJnlLine.TestField(Amount);
        VoucherJnlLine.TestField("Posting Date");
    end;


}
