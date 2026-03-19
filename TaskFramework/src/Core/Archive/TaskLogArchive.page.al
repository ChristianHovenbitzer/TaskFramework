namespace Techdays.TaskFramework.Core.Archive;

page 50002 "Task Log Archive"
{
    PageType = List;
    SourceTable = "Task Log Archive";
    Caption = 'Task Log Archive';
    Editable = false;
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Task Type"; Rec."Task Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Archived At"; Rec."Archived At") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
            }
        }
    }
}
