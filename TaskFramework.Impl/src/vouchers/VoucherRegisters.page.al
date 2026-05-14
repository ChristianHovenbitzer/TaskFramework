namespace Techdays.TaskFramework.Impl.Vouchers;

page 60012 "Voucher Registers"
{
    PageType = List;
    SourceTable = "Voucher Register";
    Caption = 'Voucher Registers';
    UsageCategory = History;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { }
                field("From Entry No."; Rec."From Entry No.") { }
                field("To Entry No."; Rec."To Entry No.") { }
                field("Creation Date"; Rec."Creation Date") { }
                field("Source Code"; Rec."Source Code") { }
                field("User ID"; Rec."User ID") { }
            }
        }
    }
}
