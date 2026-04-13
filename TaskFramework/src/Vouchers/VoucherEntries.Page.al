namespace Techdays.TaskFramework.Vouchers;

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
                    // HANDS-ON: This action posts vouchers inline — skipping ALL validation.
                    // The "Post (with Validation)" action below uses a codeunit that validates.
                    // Two posting paths with inconsistent behavior = anti-pattern.
                    //
                    // TODO: Remove the PostSelected action entirely (and PostViaCodeunit below).
                    //       Replace with a single "Post Selected" action that:
                    //       1. Gets selection filter on VoucherEntry
                    //       2. Uses ReadIsolation(IsolationLevel::UpdLock) instead of FindSet(true)
                    //       3. Calls PostVouchers.PostVoucher(VoucherEntry) for each record
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
                    // HANDS-ON: This is the second posting path — inconsistent with PostSelected above.
                    // TODO: Remove this action. Merge into a single clean "Post Selected" action.
                    PostVouchers.PostVoucher(Rec);
                end;
            }
        }
    }
}
