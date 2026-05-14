page 50004 "Voucher Entries"
{
    PageType = List;
    SourceTable = "Voucher Entry";
    Caption = 'Voucher Entries';
    ApplicationArea = All;
    UsageCategory = Lists;

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
                field(Status; Rec.Status) { }
                field(Description; Rec.Description) { }
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
