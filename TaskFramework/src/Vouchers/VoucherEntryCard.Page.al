namespace Techdays.TaskFramework.Vouchers;

// ANTI-PATTERN: This page remains fully editable even after Status = Posted.
//
// TODO: (Step 5 - Journal → Posting → Ledger Entry): this card will disappear
// along with "Voucher Entry". Replace with two pages:
//   - "Voucher Journal Lines" — editable staging list (Journal Line rows).
//   - "Voucher Ledger Entries" — read-only list over the Ledger Entry table.
// Posted records must be immutable. Enforce that by having them live in a
// different table, not just by hiding fields on a card.
page 50005 "Voucher Entry Card"
{
    PageType = Card;
    SourceTable = "Voucher Entry";
    Caption = 'Voucher Entry';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field("Voucher No."; Rec."Voucher No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
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
                ApplicationArea = All;

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
