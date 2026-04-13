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
