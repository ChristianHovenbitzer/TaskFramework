namespace Techdays.TaskFramework.Impl.Vouchers;

// HANDS-ON: Create the Voucher Ledger Entries list page.
// TODO: Add fields for Entry No., Voucher No., Customer No., Amount, Posting Date, Description, Document No., Register No.
page 60011 "Voucher Ledger Entries"
{
    PageType = List;
    SourceTable = "Voucher Ledger Entry";
    Caption = 'Voucher Ledger Entries';
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                // TODO: Add fields
            }
        }
    }
}
