using System.Utilities;

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
