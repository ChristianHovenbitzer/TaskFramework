// ANTI-PATTERN: Everything in one procedure.
//
// TODO: (Step 5 - Journal → Posting → Ledger Entry)
// TODO: (Step 6 - Collectible Errors): replace the Error() calls in Check Line
// with LogError(ErrorLog, LineNo, Message, IsBlocking) writing to "Task Error Log",
// and have Post Batch collect errors from all lines before deciding whether to
// post. Show the full error list instead of stopping on the first failure.
codeunit 50001 "Post Vouchers"
{
    var
        CustomerNoRequiredErr: Label 'Customer No. is required.';
        AmountRequiredErr: Label 'Amount must not be zero.';
        PostingDateRequiredErr: Label 'Posting Date is required.';

    procedure PostVoucher(var VoucherEntry: Record "Voucher Entry")
    begin
        // ANTI-PATTERN: Validates inline, stops on first error.
        // If Customer No. is missing AND Amount is zero, you only ever see the Customer error.
        if VoucherEntry."Customer No." = '' then
            Error(CustomerNoRequiredErr);
        if VoucherEntry.Amount = 0 then
            Error(AmountRequiredErr);
        if VoucherEntry."Posting Date" = 0D then
            Error(PostingDateRequiredErr);

        // ANTI-PATTERN: Flips status on the same record (no journal/ledger separation).
        // The "posted" record is still editable in the client. See the Step 5 TODO
        // block above — posting should create a Ledger Entry row, not mutate status.
        VoucherEntry.Status := VoucherEntry.Status::Posted;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Modify();
    end;
}
