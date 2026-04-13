namespace Techdays.TaskFramework.Impl.Vouchers;

using System.Utilities;

// HANDS-ON: Internal implementation for journal line validation.
// Uses [ErrorBehavior(ErrorBehavior::Collect)] to gather all errors before reporting.
// TODO:
//   1. Set TableNo = "Voucher Journal Line", Access = Internal
//   2. Add [ErrorBehavior(ErrorBehavior::Collect)] on RunCheck
//   3. Validate: Customer No. not empty, Amount not zero, Posting Date not 0D
//   4. Use ErrorMessageMgt.LogErrorMessage() for errors (not Error())
//   5. Use ErrorMessageMgt.LogWarning() for Description empty (warning, not error)
codeunit 60010 "Voucher Jnl.-Check Line Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure RunCheck(VoucherJnlLine: Record "Voucher Journal Line")
    begin
        // TODO: Validate required fields using ErrorMessageMgt.LogErrorMessage()
    end;
}
