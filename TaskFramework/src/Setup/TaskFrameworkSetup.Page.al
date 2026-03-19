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
