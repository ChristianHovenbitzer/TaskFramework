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
                    PostCount: Integer;
                begin
                    // ANTI-PATTERN: Business logic inline in page trigger.
                    // This is also inconsistent with the Post Vouchers codeunit which does validation.
                    // Posting here skips ALL validation — even the inline checks in PostVouchers.
                    //
                    // TODO: (Step 2 - Separation of Concerns)
                    // TODO (Step 5 - Journal → Posting → Ledger Entry): after Step 2,
                    // the remaining posting path will be replaced by
                    // "Voucher Jnl.-Post Batch" against Voucher Journal Lines.
                    CurrPage.SetSelectionFilter(VoucherEntry);
                    VoucherEntry.SetRange(Status, VoucherEntry.Status::Draft);
                    if VoucherEntry.FindSet(true) then
                        repeat
                            VoucherEntry.Status := VoucherEntry.Status::Posted;
                            VoucherEntry."Posting Date" := WorkDate();
                            VoucherEntry.Modify();
                            PostCount += 1;
                        until VoucherEntry.Next() = 0;
                    Message('Posted %1 voucher(s).', PostCount);
                end;
            }

            action(PostViaCodeunit)
            {
                Caption = 'Post (with Validation)';
                Image = PostDocument;
                ApplicationArea = All;

                trigger OnAction()
                var
                    PostVouchers: Codeunit "Post Vouchers";
                begin
                    // This one does validation (will error on missing Customer).
                    // PostSelected above skips validation entirely.
                    // Two paths, inconsistent behavior — another anti-pattern.
                    PostVouchers.PostVoucher(Rec);
                end;
            }
        }
    }
}
