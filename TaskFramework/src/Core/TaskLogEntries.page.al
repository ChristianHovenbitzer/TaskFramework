page 50000 "Task Log Entries"
{
    PageType = List;
    SourceTable = "Task Log Entry";
    Caption = 'Task Log Entries';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "Task Log Entry Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Task Processing Type"; Rec."Task Processing Type") { }
                field(Status; Rec.Status) { }
                field(Description; Rec.Description) { }
                field("Created At"; Rec."Created At") { }
                field(Verbosity; Rec.Verbosity) { }
                field("Correlation Id"; Rec."Correlation Id") { }
                field("Retry Count"; Rec."Retry Count") { }
                field("Last Error Message"; Rec."Last Error Message") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessAll)
            {
                Caption = 'Process All Pending';
                Image = Process;

                trigger OnAction()
                var
                    TaskProcessor: Codeunit "Task Processor";
                begin
                    TaskProcessor.ProcessAllPendingTasks();
                    CurrPage.Update(false);
                end;
            }

            action(CreateSampleTask)
            {
                Caption = 'Create Sample Task';
                Image = NewDocument;

                trigger OnAction()
                var
                    TaskLogEntry: Record "Task Log Entry";
                begin
                    TaskLogEntry.Init();
                    TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::LogRetention;
                    TaskLogEntry.Status := TaskLogEntry.Status::Pending;
                    TaskLogEntry.Description := SampleTaskDescLbl;
                    TaskLogEntry."Created At" := CurrentDateTime();
                    TaskLogEntry.Insert(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        SampleTaskDescLbl: Label 'Sample Task';
}
