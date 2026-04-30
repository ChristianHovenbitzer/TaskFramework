// HANDS-ON: Public facade for line validation (delegates to Impl).
// Pattern: TableNo trigger + public RunCheck procedure.
// TODO:
//   1. Set TableNo = "Voucher Journal Line"
//   2. In OnRun: call CheckLineImpl.Run(Rec)
//   3. Add RunCheck procedure that delegates to CheckLineImpl.RunCheck
codeunit 60013 "Voucher Jnl.-Check Line"
{
    TableNo = "Voucher Journal Line";

    trigger OnRun()
    begin
        CheckLineImpl.Run(Rec);
    end;

    procedure RunCheck(VoucherJnlLine: Record "Voucher Journal Line")
    begin
        CheckLineImpl.RunCheck(VoucherJnlLine);
    end;

    var
        CheckLineImpl: Codeunit "Voucher Jnl.-Check Line Impl";
}
