using System.Utilities;

codeunit 60010 "Voucher Jnl.-Check Line Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    // TODO: (Step 6 - Collectible Errors)
    // Replace TestField with ErrorMessageMgt.LogErrorMessage (and LogWarning for non-blocking issues).
    // Add [ErrorBehavior(ErrorBehavior::Collect)] so BC collects instead of throws.
    procedure RunCheck(VoucherJnlLine: Record "Voucher Journal Line")
    begin
        VoucherJnlLine.TestField("Customer No.");
        VoucherJnlLine.TestField(Amount);
        VoucherJnlLine.TestField("Posting Date");
    end;


}
