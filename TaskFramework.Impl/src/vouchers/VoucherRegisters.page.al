namespace Techdays.TaskFramework.Impl.Vouchers;

// HANDS-ON: Create the Voucher Registers list page.
// TODO: Add fields for No., From Entry No., To Entry No., Creation Date, Source Code, User ID
page 60012 "Voucher Registers"
{
    PageType = List;
    SourceTable = "Voucher Register";
    Caption = 'Voucher Registers';
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
