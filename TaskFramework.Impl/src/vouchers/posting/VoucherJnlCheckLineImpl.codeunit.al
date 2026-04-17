namespace Techdays.TaskFramework.Impl.Vouchers;

codeunit 60010 "Voucher Jnl.-Check Line Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    // TODO: (Step 6 - Collectible Errors)
    procedure RunCheck(VoucherJnlLine: Record "Voucher Journal Line")
    var
        FieldMustNotBeEmptyErr: Label '%1 is required on line %2.';
        FieldMustNotBeZeroErr: Label '%1 must not be zero on line %2.';
    begin
        if VoucherJnlLine."Customer No." = '' then
            Error(FieldMustNotBeEmptyErr, VoucherJnlLine.FieldCaption("Customer No."), VoucherJnlLine."Line No.");

        if VoucherJnlLine.Amount = 0 then
            Error(FieldMustNotBeZeroErr, VoucherJnlLine.FieldCaption(Amount), VoucherJnlLine."Line No.");

        if VoucherJnlLine."Posting Date" = 0D then
            Error(FieldMustNotBeEmptyErr, VoucherJnlLine.FieldCaption("Posting Date"), VoucherJnlLine."Line No.");

        if VoucherJnlLine.Description = '' then
            Error(FieldMustNotBeEmptyErr, VoucherJnlLine.FieldCaption(Description), VoucherJnlLine."Line No.");
    end;
}
