page 50000 "Task Log Entries"
{
    PageType = List;
    SourceTable = "Task Log Entry";
    Caption = 'Task Log Entries';
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    CardPageId = "Task Log Entry Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Task Processing Type"; Rec."Task Processing Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field(Verbosity; Rec.Verbosity) { ApplicationArea = All; }
                field("Correlation Id"; Rec."Correlation Id") { ApplicationArea = All; }
                field("Retry Count"; Rec."Retry Count") { ApplicationArea = All; }
                field("Last Error Message"; Rec."Last Error Message") { ApplicationArea = All; }
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
                ApplicationArea = All;

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
                ApplicationArea = All;

                trigger OnAction()
                var
                    TaskLogEntry: Record "Task Log Entry";
                begin
                    TaskLogEntry.Init();
                    // TODO: (Step 3 - DI / Strategy via Interfaces): once VendorImport
                    // moves to the Impl enum extension, the framework page can't
                    // reference it. Switch this default to LogRetention.
                    TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::VendorImport;
                    TaskLogEntry.Status := TaskLogEntry.Status::Pending;
                    TaskLogEntry.Description := 'Sample Task';
                    TaskLogEntry."Created At" := CurrentDateTime;
                    TaskLogEntry.Insert(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
