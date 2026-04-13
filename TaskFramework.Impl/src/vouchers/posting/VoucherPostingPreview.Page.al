namespace Techdays.TaskFramework.Impl.Vouchers;

// HANDS-ON: Preview page showing temporary ledger entries from a simulated posting.
// TODO: Add fields for all ledger entry columns
page 60013 "Voucher Posting Preview"
{
    PageType = List;
    SourceTable = "Voucher Ledger Entry";
    SourceTableTemporary = true;
    Caption = 'Voucher Posting Preview';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                // TODO: Add fields for Entry No., Voucher No., Customer No., Amount, Posting Date, Description, Document No., Register No.
            }
        }
    }
}
