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
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Voucher No."; Rec."Voucher No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Register No."; Rec."Register No.") { ApplicationArea = All; }
            }
        }
    }
}
