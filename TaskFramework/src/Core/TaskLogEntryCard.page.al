page 50001 "Task Log Entry Card"
{
    PageType = Card;
    SourceTable = "Task Log Entry";
    Caption = 'Task Log Entry';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.") { Editable = false; }
                field("Task Processing Type"; Rec."Task Processing Type") { }
                field(Status; Rec.Status) { }
                field(Description; Rec.Description) { }
                field("Created At"; Rec."Created At") { }
                field("Processing Started At"; Rec."Processing Started At") { }
                field("Processing Completed At"; Rec."Processing Completed At") { }
                field("Last Error Message"; Rec."Last Error Message") { }
                field("Retry Count"; Rec."Retry Count") { }
                field("Error Handler"; Rec."Error Handler") { }
                field(Verbosity; Rec.Verbosity) { }
                field("Correlation Id"; Rec."Correlation Id") { Editable = false; }
                field("Archive After Processing"; Rec."Archive After Processing") { }
                field("Earliest Processing DateTime"; Rec."Earliest Processing DateTime") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Process)
            {
                Caption = 'Process';
                Image = Process;

                trigger OnAction()
                var
                    TaskProcessor: Codeunit "Task Processor";
                begin
                    TaskProcessor.ProcessTaskEntry(Rec);
                end;
            }
        }
    }
}
