namespace Techdays.TaskFramework.Impl.Vouchers;

// HANDS-ON: Create the Voucher Journal page (Worksheet type).
// TODO:
//   1. Add fields for all journal line columns in a repeater
//   2. Add a "Post" action (F9) that calls "Voucher Jnl.-Post Batch Impl".Run()
//   3. Add a "Preview Posting" action that calls "Voucher Jnl.-Post Preview".Preview()
//   4. Add footer totals (Number of Lines, Total Amount)
page 60010 "Voucher Journal"
{
    PageType = Worksheet;
    SourceTable = "Voucher Journal Line";
    Caption = 'Voucher Journal';
    UsageCategory = Tasks;
    ApplicationArea = All;
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                // TODO: Add fields for Voucher No., Posting Date, Document No., Customer No., Description, Amount
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Posting)
            {
                Caption = 'Posting';
                Image = Post;

                // TODO: Add Post and Preview actions
            }
        }
    }
}
