namespace Techdays.TaskFramework.Impl.Vouchers;

page 60010 "Voucher Journal Lines"
{
    PageType = List;
    SourceTable = "Voucher Journal Line";
    Caption = 'Voucher Journal';
    UsageCategory = Lists;
    ApplicationArea = All;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Voucher No."; Rec."Voucher No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post)
            {
                Caption = 'Post';
                Image = PostBatch;
                ApplicationArea = All;

                trigger OnAction()
                var
                    VoucherJnlLine: Record "Voucher Journal Line";
                    PostBatch: Codeunit "Voucher Jnl.-Post Batch Impl";
                begin
                    VoucherJnlLine.Copy(Rec);
                    PostBatch.Run(VoucherJnlLine);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
