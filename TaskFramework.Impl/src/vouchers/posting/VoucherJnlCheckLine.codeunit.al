// PROVIDED (Step 5): public facade for the Check Line pipeline stage. Forwards every
// call to the internal Impl below. All three facades follow this same shape.
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
