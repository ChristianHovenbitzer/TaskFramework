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
    var
        CheckLine: Codeunit "Voucher Jnl.-Check Line Impl";
        PostLine: Codeunit "Voucher Jnl.-Post Line Impl";
        PostPreview: Codeunit "Voucher Jnl.-Post Preview";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        Register: Record "Voucher Register";
        NextRegisterNo: Integer;
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        if not VoucherJnlLine.FindSet() then
            Error(NothingToPostErr);

        // Phase 1: Validate all lines, collecting all errors
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        repeat
            CheckLine.RunCheck(VoucherJnlLine);
        until VoucherJnlLine.Next() = 0;

        if ErrorMessageHandler.HasErrors() then begin
            ErrorMessageHandler.ShowErrors();
            Error('');
        end;


        // Phase 2: Create register
        NextRegisterNo := GetNextRegisterNo();
        Register := InsertNewRegisterEntry(NextRegisterNo);

        PostLine.SetNextRegisterNo(Register."No.");
        PostLine.InitNextEntryNo();

        // Phase 3: Post all lines
        VoucherJnlLine.FindSet();
        repeat
            PostLine.RunPosting(VoucherJnlLine, Register."No.");

            if FirstEntryNo = 0 then
                FirstEntryNo := PostLine.GetNextEntryNo();
            LastEntryNo := PostLine.GetNextEntryNo();
        until VoucherJnlLine.Next() = 0;

        // Phase 4: Update register with entry range
        UpdateRegister(Register, FirstEntryNo, LastEntryNo);

        // Phase 5: Delete posted journal lines
        VoucherJnlLine.DeleteAll(true);

        if PostPreview.IsActive() then
            PostPreview.ThrowError();
    end;

    local procedure GetNextRegisterNo() NextRegisterNo: Integer
    var
        Register: Record "Voucher Register";
    begin
        Register.ReadIsolation := IsolationLevel::UpdLock;
        if Register.FindLast() then
            NextRegisterNo := Register."No." + 1
        else
            NextRegisterNo := 1;
    end;

    local procedure InsertNewRegisterEntry(var NextRegisterNo: Integer) Register: Record "Voucher Register"
    begin
        Register.Init();
        Register.Validate("No.", NextRegisterNo);
        Register.Validate("Creation Date", Today());
        Register.Validate("User ID", CopyStr(UserId(), 1, MaxStrLen(Register."User ID")));
        Register.Insert(true);
    end;

    local procedure UpdateRegister(var Register: Record "Voucher Register"; var FirstEntryNo: Integer; var LastEntryNo: Integer) UpdatedRegisterEntry: Record "Voucher Register"
    begin
        Register.Validate("From Entry No.", FirstEntryNo);
        Register.Validate("To Entry No.", LastEntryNo);
        Register.Modify(true);

        exit(Register);
    end;

    var
        NothingToPostErr: Label 'There is nothing to post.';
}
