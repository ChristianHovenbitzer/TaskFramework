namespace Techdays.TaskFramework.Impl.Vouchers;

page 60011 "Voucher Ledger Entries"
{
    PageType = List;
    SourceTable = "Voucher Ledger Entry";
    Caption = 'Voucher Ledger Entries';
    UsageCategory = History;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Voucher No."; Rec."Voucher No.") { }
                field("Customer No."; Rec."Customer No.") { }
                field(Amount; Rec.Amount) { }
                field("Posting Date"; Rec."Posting Date") { }
                field(Description; Rec.Description) { }
                field("Document No."; Rec."Document No.") { }
                field("Register No."; Rec."Register No.") { }
            }
        }
    }
}
