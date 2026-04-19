namespace Techdays.TaskFramework.Impl.Vouchers;

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
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("From Entry No."; Rec."From Entry No.") { ApplicationArea = All; }
                field("To Entry No."; Rec."To Entry No.") { ApplicationArea = All; }
                field("Creation Date"; Rec."Creation Date") { ApplicationArea = All; }
                field("Source Code"; Rec."Source Code") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
            }
        }
    }
}
