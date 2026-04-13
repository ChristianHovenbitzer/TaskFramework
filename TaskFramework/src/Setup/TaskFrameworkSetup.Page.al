namespace Techdays.TaskFramework.Setup;

page 50003 "Task Framework Setup"
{
    PageType = Card;
    SourceTable = "Task Framework Setup";
    Caption = 'Task Framework Setup';
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Enabled; Rec.Enabled) { ApplicationArea = All; }
                field("Max Retry Count"; Rec."Max Retry Count") { ApplicationArea = All; }
                field("Default G/L Account"; Rec."Default G/L Account") { ApplicationArea = All; }
                field("Default Verbosity"; Rec."Default Verbosity") { ApplicationArea = All; }
                field("Default Error Handler"; Rec."Default Error Handler") { ApplicationArea = All; }
            }
            group(Scheduling)
            {
                Caption = 'Scheduling';
                field("Execution Interval (Seconds)"; Rec."Execution Interval (Seconds)") { ApplicationArea = All; }
                field("Last Processed At"; Rec."Last Processed At") { ApplicationArea = All; Editable = false; }
            }
            group(Batching)
            {
                Caption = 'Batching';
                field("Enable Batches"; Rec."Enable Batches") { ApplicationArea = All; }
                field("Batch Size"; Rec."Batch Size") { ApplicationArea = All; }
            }
            group(Archive)
            {
                Caption = 'Archive';
                field("Archive Enabled"; Rec."Archive Enabled") { ApplicationArea = All; }
                // TODO: Add a field for "Retention Days" here once you've added the table field
                field("Retention Days"; Rec."Retention Days") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "Task Framework Setup";
    begin
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
    end;
}
