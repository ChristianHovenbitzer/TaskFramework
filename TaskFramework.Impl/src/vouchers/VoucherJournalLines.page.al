page 60010 "Voucher Journal"
{
    PageType = Worksheet;
    SourceTable = "Voucher Journal Line";
    Caption = 'Voucher Journal';
    ApplicationArea = All;
    UsageCategory = Tasks;
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Voucher No."; Rec."Voucher No.") { }
                field("Posting Date"; Rec."Posting Date") { }
                field("Document No."; Rec."Document No.") { }
                field("Customer No."; Rec."Customer No.") { }
                field(Description; Rec.Description) { }
                field(Amount; Rec.Amount) { }
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
                        { Caption = 'Number of Lines';
                            Editable = false;
                            ToolTip = 'Specifies the number of journal lines.';
                        }
                    }
                    group("Total Amount")
                    {
                        Caption = 'Total Amount';
                        field(TotalAmount; TotalAmount)
                        { AutoFormatType = 1;
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
