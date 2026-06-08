using System.Utilities;

// WORKED EXAMPLE (Step 5): this Check Line pair is provided complete as your
// reference for the Public/Impl pattern — build Post Line and Post Batch the same way.
// Internal Impl carrying the validation logic. Uses TestField so missing-field errors
// carry the field name. Errors get collected (not bail-on-first) when called from
// PostBatch under [ErrorBehavior(Collect)].
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
