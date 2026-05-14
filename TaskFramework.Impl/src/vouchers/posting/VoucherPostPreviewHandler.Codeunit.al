// TODO: (Step 5 - Journal → Posting → Ledger Entry): manual subscriber that the
// preview activates via BindSubscription. Captures would-be ledger entries into a
// temp record so the preview page can show them after the rollback.
codeunit 60016 "Voucher Post. Preview Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Voucher Jnl.-Post Line Impl", OnAfterPostVoucherLine, '', false, false)]
    local procedure OnAfterPostVoucherLine(var VoucherLedgerEntry: Record "Voucher Ledger Entry")
    begin
        TempVoucherLedgerEntry := VoucherLedgerEntry;
        TempVoucherLedgerEntry.Insert(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Voucher Jnl.-Post Preview", OnCheckPostingPreviewActive, '', false, false)]
    local procedure OnCheckPostingPreviewActive(var IsActive: Boolean)
    begin
        IsActive := true;
    end;

    procedure GetEntries(var TempEntries: Record "Voucher Ledger Entry" temporary)
    begin
        TempEntries.Copy(TempVoucherLedgerEntry, true);
    end;

    var
        TempVoucherLedgerEntry: Record "Voucher Ledger Entry" temporary;
}
