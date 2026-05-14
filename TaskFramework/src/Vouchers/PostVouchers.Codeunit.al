// ANTI-PATTERN: Everything in one procedure.
// Step 5 will replace with: Jnl.-Check Line + Jnl.-Post Line + Jnl.-Post Batch
// Step 6 will replace Error() with Collectible Errors
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
        // The "posted" record is still editable in the client.
        VoucherEntry.Status := VoucherEntry.Status::Posted;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Modify(false);
    end;
}
