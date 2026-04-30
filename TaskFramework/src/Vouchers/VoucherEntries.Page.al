page 50004 "Voucher Entries"
{
    PageType = List;
    SourceTable = "Voucher Entry";
    Caption = 'Voucher Entries';
    UsageCategory = Lists;
    ApplicationArea = All;

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
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostSelected)
            {
                Caption = 'Post Selected';
                Image = Post;
                ApplicationArea = All;

                trigger OnAction()
                var
                    VoucherEntry: Record "Voucher Entry";
                    PostVouchers: Codeunit "Post Vouchers";
                begin
                    CurrPage.SetSelectionFilter(VoucherEntry);
                    VoucherEntry.ReadIsolation(IsolationLevel::UpdLock);
                    if VoucherEntry.FindSet() then
                        repeat
                            PostVouchers.PostVoucher(VoucherEntry);
                        until VoucherEntry.Next() = 0;
                end;
            }
        }
    }
}
