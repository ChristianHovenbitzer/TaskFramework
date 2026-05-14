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
                    PostCount: Integer;
                begin
                    // ANTI-PATTERN: Business logic inline in page trigger.
                    // This is also inconsistent with the Post Vouchers codeunit which does validation.
                    // Posting here skips ALL validation — even the inline checks in PostVouchers.
                    //
                    // TODO: (Step 2 - Separation of Concerns)
                    CurrPage.SetSelectionFilter(VoucherEntry);
                    VoucherEntry.SetRange(Status, VoucherEntry.Status::Draft);
                    if VoucherEntry.FindSet(true) then
                        repeat
                            VoucherEntry.Status := VoucherEntry.Status::Posted;
                            VoucherEntry."Posting Date" := WorkDate();
                            VoucherEntry.Modify(false);
                            PostCount += 1;
                        until VoucherEntry.Next() = 0;
                    Message('Posted %1 voucher(s).', PostCount);
                end;
            }

            action(PostViaCodeunit)
            {
                Caption = 'Post (with Validation)';
                Image = PostDocument;

                trigger OnAction()
                var
                    PostVouchers: Codeunit "Post Vouchers";
                begin
                    // This one does validation (will error on missing Customer).
                    // PostSelected above skips validation entirely.
                    // Two paths, inconsistent behavior — another anti-pattern.
                    // TODO: (Step 2 - Separation of Concerns): delete this action;
                    // PostSelected above is the consolidated path.
                    PostVouchers.PostVoucher(Rec);
                end;
            }
        }
    }
}
