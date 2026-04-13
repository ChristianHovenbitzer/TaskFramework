namespace Techdays.TaskFramework.Impl.Vouchers;

// HANDS-ON: Internal implementation for posting a single journal line to a ledger entry.
// TODO:
//   1. Set TableNo = "Voucher Journal Line", Access = Internal
//   2. InitNextEntryNo: find last ledger entry, set NextEntryNo
//   3. RunPosting: create a Voucher Ledger Entry from the journal line
//      - Increment NextEntryNo, map all fields, set Register No.
//   4. Publish OnAfterPostVoucherLine integration event (for preview handler)
//   5. Add GetNextEntryNo/SetNextRegisterNo accessors
codeunit 60011 "Voucher Jnl.-Post Line Impl"
{
    Access = Internal;
    TableNo = "Voucher Journal Line";
    Permissions = tabledata "Voucher Ledger Entry" = ri;

    trigger OnRun()
    begin
        RunPosting(Rec);
    end;

    procedure RunPosting(VoucherJnlLine: Record "Voucher Journal Line")
    begin
        // TODO: Create Voucher Ledger Entry from journal line
    end;

    procedure InitNextEntryNo()
    begin
        // TODO: Find last entry, set NextEntryNo
    end;

    procedure RunPosting(VoucherJnlLine: Record "Voucher Journal Line"; RegisterNo: Integer)
    begin
        // TODO: Post with specific register number
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostVoucherLine(var VoucherLedgerEntry: Record "Voucher Ledger Entry")
    begin
    end;

    procedure GetNextEntryNo(): Integer
    begin
        exit(NextEntryNo);
    end;

    procedure SetNextRegisterNo(RegisterNo: Integer)
    begin
        NextRegisterNo := RegisterNo;
    end;

    var
        NextEntryNo: Integer;
        NextRegisterNo: Integer;
}
