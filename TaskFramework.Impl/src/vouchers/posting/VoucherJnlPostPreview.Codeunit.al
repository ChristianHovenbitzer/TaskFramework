namespace Techdays.TaskFramework.Impl.Vouchers;

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
        // TODO: Implement posting preview
    end;

    procedure IsActive(): Boolean
    begin
        // TODO: Check via event if preview is active
        exit(false);
    end;

    procedure ThrowError()
    begin
        // TODO: Error(PreviewModeErr);
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
