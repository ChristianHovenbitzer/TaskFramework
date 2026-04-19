namespace Techdays.TaskFramework.Impl.Vouchers;

using System.Utilities;

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
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        FieldMustNotBeEmptyErr: Label '%1 is required on line %2.';
        FieldMustNotBeZeroErr: Label '%1 must not be zero on line %2.';
    begin
        if VoucherJnlLine."Customer No." = '' then
            ErrorMessageMgt.LogErrorMessage(
                VoucherJnlLine.FieldNo("Customer No."),
                StrSubstNo(FieldMustNotBeEmptyErr, VoucherJnlLine.FieldCaption("Customer No."), VoucherJnlLine."Line No."),
                VoucherJnlLine,
                VoucherJnlLine.FieldNo("Customer No."),
                '');

        if VoucherJnlLine.Amount = 0 then
            ErrorMessageMgt.LogErrorMessage(
                VoucherJnlLine.FieldNo(Amount),
                StrSubstNo(FieldMustNotBeZeroErr, VoucherJnlLine.FieldCaption(Amount), VoucherJnlLine."Line No."),
                VoucherJnlLine,
                VoucherJnlLine.FieldNo(Amount),
                '');

        if VoucherJnlLine."Posting Date" = 0D then
            ErrorMessageMgt.LogErrorMessage(
                VoucherJnlLine.FieldNo("Posting Date"),
                StrSubstNo(FieldMustNotBeEmptyErr, VoucherJnlLine.FieldCaption("Posting Date"), VoucherJnlLine."Line No."),
                VoucherJnlLine,
                VoucherJnlLine.FieldNo("Posting Date"),
                '');

        if VoucherJnlLine.Description = '' then
            ErrorMessageMgt.LogWarning(
                VoucherJnlLine.FieldNo(Description),
                StrSubstNo(FieldMustNotBeEmptyErr, VoucherJnlLine.FieldCaption(Description), VoucherJnlLine."Line No."),
                VoucherJnlLine,
                VoucherJnlLine.FieldNo(Description),
                ''
            )
    end;


}
