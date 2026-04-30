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
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field("Task Processing Type"; Rec."Task Processing Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Processing Started At"; Rec."Processing Started At") { ApplicationArea = All; }
                field("Processing Completed At"; Rec."Processing Completed At") { ApplicationArea = All; }
                field("Last Error Message"; Rec."Last Error Message") { ApplicationArea = All; }
                field("Retry Count"; Rec."Retry Count") { ApplicationArea = All; }
                field("Error Handler"; Rec."Error Handler") { ApplicationArea = All; }
                field(Verbosity; Rec.Verbosity) { ApplicationArea = All; }
                field("Correlation Id"; Rec."Correlation Id") { ApplicationArea = All; Editable = false; }
                field("Archive After Processing"; Rec."Archive After Processing") { ApplicationArea = All; }
                field("Earliest Processing DateTime"; Rec."Earliest Processing DateTime") { ApplicationArea = All; }
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
                ApplicationArea = All;

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
