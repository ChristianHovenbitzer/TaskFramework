namespace Techdays.TaskFramework.Impl.Vouchers;

codeunit 60010 "Voucher Jnl.-Check Line Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    procedure RunCheck(VoucherJnlLine: Record "Voucher Journal Line")
    var
        FieldMustNotBeEmptyErr: Label '%1 is required on line %2.';
        FieldMustNotBeZeroErr: Label '%1 must not be zero on line %2.';
    begin
        VoucherJnlLine.TestField("Customer No.");
        VoucherJnlLine.TestField(Amount);
        VoucherJnlLine.TestField("Posting Date");
    end;

}
