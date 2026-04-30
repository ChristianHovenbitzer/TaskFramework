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
