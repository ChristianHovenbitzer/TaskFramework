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

    // TODO: (Step 6 - Collectible Errors)
    procedure PostBatch(var VoucherJnlLine: Record "Voucher Journal Line")
    var
        CheckLine: Codeunit "Voucher Jnl.-Check Line Impl";
        PostLine: Codeunit "Voucher Jnl.-Post Line Impl";
        PostPreview: Codeunit "Voucher Jnl.-Post Preview";
        Register: Record "Voucher Register";
        NextRegisterNo: Integer;
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        if not VoucherJnlLine.FindSet() then
            Error(NothingToPostErr);

        // Phase 1: Validate all lines (stops at first error — TODO: collect instead)
        repeat
            CheckLine.RunCheck(VoucherJnlLine);
        until VoucherJnlLine.Next() = 0;

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
