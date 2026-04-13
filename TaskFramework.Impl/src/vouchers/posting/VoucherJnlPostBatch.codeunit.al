namespace Techdays.TaskFramework.Impl.Vouchers;

// HANDS-ON: Public facade for batch posting (delegates to Impl).
// TODO:
//   1. Set TableNo = "Voucher Journal Line"
//   2. Add Permissions for journal line (rd), ledger entry (ri), register (rim)
//   3. OnRun: call PostBatchImpl.Run(Rec)
//   4. Add PostBatch procedure that delegates to PostBatchImpl
codeunit 60015 "Voucher Jnl.-Post Batch"
{
    TableNo = "Voucher Journal Line";
    Permissions = tabledata "Voucher Journal Line" = rd,
                  tabledata "Voucher Ledger Entry" = ri,
                  tabledata "Voucher Register" = rim;

    trigger OnRun()
    begin
        // TODO: PostBatchImpl.Run(Rec);
    end;

    procedure PostBatch(var VoucherJnlLine: Record "Voucher Journal Line")
    begin
        // TODO: PostBatchImpl.PostBatch(VoucherJnlLine);
    end;

    var
        PostBatchImpl: Codeunit "Voucher Jnl.-Post Batch Impl";
}
