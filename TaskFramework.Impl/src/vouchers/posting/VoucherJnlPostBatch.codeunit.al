codeunit 60015 "Voucher Jnl.-Post Batch"
{
    TableNo = "Voucher Journal Line";
    Permissions = tabledata "Voucher Journal Line" = rd,
                  tabledata "Voucher Ledger Entry" = ri,
                  tabledata "Voucher Register" = rim;

    trigger OnRun()
    begin
        PostBatchImpl.Run(Rec);
    end;

    procedure PostBatch(var VoucherJnlLine: Record "Voucher Journal Line")
    begin
        PostBatchImpl.PostBatch(VoucherJnlLine);
    end;

    var
        PostBatchImpl: Codeunit "Voucher Jnl.-Post Batch Impl";
}
