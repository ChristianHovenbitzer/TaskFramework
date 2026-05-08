// TODO: (Step 5 - Journal → Posting → Ledger Entry): public facade for the
// Post Line stage. Forwards to the internal Impl. Permissions on Voucher Ledger
// Entry are declared here.
codeunit 60014 "Voucher Jnl.-Post Line"
{
    TableNo = "Voucher Journal Line";
    Permissions = tabledata "Voucher Ledger Entry" = ri;

    trigger OnRun()
    begin
        PostLineImpl.Run(Rec);
    end;

    procedure InitNextEntryNo()
    begin
        PostLineImpl.InitNextEntryNo();
    end;

    procedure RunPosting(VoucherJnlLine: Record "Voucher Journal Line")
    begin
        PostLineImpl.RunPosting(VoucherJnlLine);
    end;

    procedure RunPosting(VoucherJnlLine: Record "Voucher Journal Line"; RegisterNo: Integer)
    begin
        PostLineImpl.RunPosting(VoucherJnlLine, RegisterNo);
    end;

    procedure GetNextEntryNo(): Integer
    begin
        exit(PostLineImpl.GetNextEntryNo());
    end;

    procedure SetNextRegisterNo(RegisterNo: Integer)
    begin
        PostLineImpl.SetNextRegisterNo(RegisterNo);
    end;

    var
        PostLineImpl: Codeunit "Voucher Jnl.-Post Line Impl";
}
