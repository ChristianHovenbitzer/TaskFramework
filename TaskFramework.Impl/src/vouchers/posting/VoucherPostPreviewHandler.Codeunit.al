namespace Techdays.TaskFramework.Impl.Vouchers;

// HANDS-ON: Manual event subscriber for the posting preview.
// Captures posted ledger entries into a temporary table during preview.
// TODO:
//   1. Set Access = Internal, EventSubscriberInstance = Manual
//   2. Subscribe to OnAfterPostVoucherLine — capture entry into temp table
//   3. Subscribe to OnCheckPostingPreviewActive — set IsActive = true
//   4. Add GetEntries procedure to return captured entries
codeunit 60016 "Voucher Post. Preview Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Voucher Jnl.-Post Line Impl", OnAfterPostVoucherLine, '', false, false)]
    local procedure OnAfterPostVoucherLine(var VoucherLedgerEntry: Record "Voucher Ledger Entry")
    begin
        TempVoucherLedgerEntry := VoucherLedgerEntry;
        TempVoucherLedgerEntry.Insert();
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
