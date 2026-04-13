namespace Techdays.TaskFramework.Impl.Vouchers;

using System.Utilities;

// HANDS-ON: Internal implementation for batch posting.
// This is the core posting pipeline — follows the BC pattern:
//   Phase 1: Validate all lines (collect errors)
//   Phase 2: Create register
//   Phase 3: Post all lines (create ledger entries)
//   Phase 4: Update register with entry range
//   Phase 5: Delete posted journal lines
//
// TODO:
//   1. Set TableNo, Access = Internal, Permissions
//   2. Add [ErrorBehavior(ErrorBehavior::Collect)] on PostBatch
//   3. Phase 1: Loop through lines, call CheckLine.RunCheck(), collect errors
//   4. Phase 2: GetNextRegisterNo, InsertNewRegisterEntry
//   5. Phase 3: Loop through lines, call PostLine.RunPosting(), track first/last entry
//   6. Phase 4: UpdateRegister with entry range
//   7. Phase 5: DeleteAll posted journal lines
//   8. Handle preview mode (PostPreview.IsActive/ThrowError)
codeunit 60012 "Voucher Jnl.-Post Batch Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";
    Permissions = tabledata "Voucher Journal Line" = rd,
                  tabledata "Voucher Ledger Entry" = ri,
                  tabledata "Voucher Register" = rim;

    trigger OnRun()
    begin
        PostBatch(Rec);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure PostBatch(var VoucherJnlLine: Record "Voucher Journal Line")
    begin
        // TODO: Implement the 5-phase posting pipeline
    end;

    var
        NothingToPostErr: Label 'There is nothing to post.';
}
