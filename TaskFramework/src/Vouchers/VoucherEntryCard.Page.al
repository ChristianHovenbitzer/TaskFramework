// ANTI-PATTERN: This page remains fully editable even after Status = Posted.
//
// TODO: (Step 5 - Journal → Posting → Ledger Entry)
page 50005 "Voucher Entry Card"
{
    PageType = Card;
    SourceTable = "Voucher Entry";
    Caption = 'Voucher Entry';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.") { Editable = false; }
                field("Voucher No."; Rec."Voucher No.") { }
                field("Customer No."; Rec."Customer No.") { }
                field(Amount; Rec.Amount) { }
                field("Posting Date"; Rec."Posting Date") { }
                field(Status; Rec.Status) { }
                field(Description; Rec.Description) { }
                field("Document No."; Rec."Document No.") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostViaCodeunit)
            {
                Caption = 'Post (with Validation)';
                Image = PostDocument;

                trigger OnAction()
                var
                    PostVouchers: Codeunit "Post Vouchers";
                begin
                    PostVouchers.PostVoucher(Rec);
                end;
            }
        }
    }
}
