page 50002 "Task Log Archive"
{
    PageType = List;
    SourceTable = "Task Log Archive";
    Caption = 'Task Log Archive';
    Editable = false;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Task Type"; Rec."Task Type") { }
                field(Status; Rec.Status) { }
                field("Archive Reason"; Rec."Archive Reason") { }
                field(Description; Rec.Description) { }
                field("Archived At"; Rec."Archived At") { }
                field("Correlation Id"; Rec."Correlation Id") { }
                field(Verbosity; Rec.Verbosity) { }
                field("Created At"; Rec."Created At") { }
            }
        }
    }
}
