namespace Techdays.TaskFramework.Impl.Vouchers;

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
                field("Voucher No."; Rec."Voucher No.") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
            group(Footer)
            {
                ShowCaption = false;
                fixed(Totals)
                {
                    ShowCaption = false;
                    group("Number of Lines")
                    {
                        Caption = 'Number of Lines';
                        field(NumberOfLines; NumberOfLines)
                        {
                            ApplicationArea = All;
                            Caption = 'Number of Lines';
                            Editable = false;
                            ToolTip = 'Specifies the number of journal lines.';
                        }
                    }
                    group("Total Amount")
                    {
                        Caption = 'Total Amount';
                        field(TotalAmount; TotalAmount)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total amount of all journal lines.';
                        }
                    }
                }
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

                action(Post)
                {
                    Caption = 'P&ost';
                    Image = PostBatch;
                    ApplicationArea = All;
                    ShortcutKey = 'F9';

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
                action(Preview)
                {
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        VoucherJnlLine: Record "Voucher Journal Line";
                        PostPreview: Codeunit "Voucher Jnl.-Post Preview";
                    begin
                        VoucherJnlLine.Copy(Rec);
                        PostPreview.Preview(VoucherJnlLine);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post) { }
                actionref(Preview_Promoted; Preview) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateTotals();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateTotals();
    end;

    local procedure UpdateTotals()
    var
        VoucherJnlLine: Record "Voucher Journal Line";
    begin
        VoucherJnlLine.CopyFilters(Rec);
        NumberOfLines := VoucherJnlLine.Count();
        VoucherJnlLine.CalcSums(Amount);
        TotalAmount := VoucherJnlLine.Amount;
    end;

    var
        NumberOfLines: Integer;
        TotalAmount: Decimal;
}
