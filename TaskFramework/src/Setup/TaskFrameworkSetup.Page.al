page 50003 "Task Framework Setup"
{
    PageType = Card;
    SourceTable = "Task Framework Setup";
    Caption = 'Task Framework Setup';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Enabled; Rec.Enabled) { }
                field("Max Retry Count"; Rec."Max Retry Count") { }
                field("Default G/L Account"; Rec."Default G/L Account") { }
                field("Default Verbosity"; Rec."Default Verbosity") { }
                field("Default Error Handler"; Rec."Default Error Handler") { }
            }
            group(Scheduling)
            {
                Caption = 'Scheduling';
                field("Execution Interval (Seconds)"; Rec."Execution Interval (Seconds)") { }
                field("Last Processed At"; Rec."Last Processed At") { Editable = false; }
            }
            group(Batching)
            {
                Caption = 'Batching';
                field("Enable Batches"; Rec."Enable Batches") { }
                field("Batch Size"; Rec."Batch Size") { }
            }
            group(Archive)
            {
                Caption = 'Archive';
                field("Archive Enabled"; Rec."Archive Enabled") { }
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "Task Framework Setup";
    begin
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(false);
        end;
    end;
}
