namespace Techdays.TaskFramework.Impl.Vouchers;

codeunit 60010 "Voucher Jnl.-Check Line Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    // TODO (Step 6 - Collectible Errors):
    // This procedure currently stops at the first validation failure, so the user only
    // sees one error per posting attempt. Convert it to collect ALL errors for a line
    // using the standard BC pattern:
    //   - Mark the procedure with [ErrorBehavior(ErrorBehavior::Collect)]
    //   - Use Codeunit "Error Message Management".LogErrorMessage(...) instead of Error()
    //   - Use LogWarning(...) for the Description check (warning, not blocker)
    // The Description field should become a warning, not a hard error.
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
