namespace Techdays.TaskFramework.Impl.Vouchers;

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

    procedure PostBatch(var VoucherJnlLine: Record "Voucher Journal Line")
    var
        CheckLine: Codeunit "Voucher Jnl.-Check Line Impl";
        PostLine: Codeunit "Voucher Jnl.-Post Line Impl";
        PostPreview: Codeunit "Voucher Jnl.-Post Preview";
        Register: Record "Voucher Register";
        NothingToPostErr: Label 'There is nothing to post.';
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        if not VoucherJnlLine.FindSet() then
            Error(NothingToPostErr);

        repeat
            CheckLine.RunCheck(VoucherJnlLine);
        until VoucherJnlLine.Next() = 0;

        Register.Init();
        Register.Validate("Creation Date", Today());
        Register.Validate("User ID", CopyStr(UserId(), 1, MaxStrLen(Register."User ID")));
        Register.Insert(true);

        PostLine.SetNextRegisterNo(Register."No.");
        PostLine.InitNextEntryNo();

        VoucherJnlLine.FindSet();
        repeat
            PostLine.RunPosting(VoucherJnlLine, Register."No.");

            if FirstEntryNo = 0 then
                FirstEntryNo := PostLine.GetNextEntryNo();
            LastEntryNo := PostLine.GetNextEntryNo();
        until VoucherJnlLine.Next() = 0;

        Register.Validate("From Entry No.", FirstEntryNo);
        Register.Validate("To Entry No.", LastEntryNo);
        Register.Modify(true);

        VoucherJnlLine.DeleteAll(true);

        if PostPreview.IsActive() then
            PostPreview.ThrowError();
    end;

}
