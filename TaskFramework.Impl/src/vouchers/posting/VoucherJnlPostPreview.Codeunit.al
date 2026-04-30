// HANDS-ON: Posting preview codeunit.
// Uses [CommitBehavior(CommitBehavior::Error)] to run posting in a rollback transaction.
// TODO:
//   1. Add Preview procedure that calls PreviewStart with CommitBehavior::Error
//   2. In PreviewStart: BindSubscription(PreviewHandler), run PostBatch, UnbindSubscription
//   3. Check if preview succeeded, get temp entries, show preview page
//   4. Add IsActive/IsSuccess/ThrowError helper procedures
//   5. Publish OnCheckPostingPreviewActive event (for the handler to subscribe to)
codeunit 60017 "Voucher Jnl.-Post Preview"
{
    Access = Internal;

    procedure Preview(var VoucherJnlLine: Record "Voucher Journal Line")
    begin
        PreviewStart(VoucherJnlLine);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PreviewStart(var VoucherJnlLine: Record "Voucher Journal Line")
    var
        PostBatch: Codeunit "Voucher Jnl.-Post Batch Impl";
        PreviewHandler: Codeunit "Voucher Post. Preview Handler";
        TempLedgerEntry: Record "Voucher Ledger Entry" temporary;
        RunResult: Boolean;
    begin
        BindSubscription(PreviewHandler);

        RunResult := PostBatch.Run(VoucherJnlLine);

        UnbindSubscription(PreviewHandler);

        if RunResult or (GetLastErrorCallStack() = '') then
            Error(PreviewExitStateErr);

        LastErrorText := GetLastErrorText();
        if not IsSuccess() then
            Error(LastErrorText);

        PreviewHandler.GetEntries(TempLedgerEntry);
        if not TempLedgerEntry.FindFirst() then
            Error(NothingToPreviewErr);

        Page.Run(Page::"Voucher Posting Preview", TempLedgerEntry);
        Error('');
    end;

    procedure IsActive(): Boolean
    var
        Result: Boolean;
    begin
        OnCheckPostingPreviewActive(Result);
        exit(Result);
    end;

    procedure IsSuccess(): Boolean
    begin
        exit(LastErrorText = PreviewModeErr);
    end;

    procedure ThrowError()
    begin
        Error(PreviewModeErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPostingPreviewActive(var IsActive: Boolean)
    begin
    end;

    var
        LastErrorText: Text;
        PreviewModeErr: Label 'Preview mode.';
        PreviewExitStateErr: Label 'The posting preview has stopped because of a state that is not valid.';
        NothingToPreviewErr: Label 'There is nothing to preview.';
}
