namespace Techdays.TaskFramework.Core;

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
                field("Task Type"; Rec."Task Type") { ApplicationArea = All; }
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
                begin
                    // ANTI-PATTERN: Business logic directly in page trigger.
                    // This bypasses the Task Processor codeunit entirely.
                    //
                    // TODO (Step 2 - Separation of Concerns): remove ALL of the body
                    // below and replace with a single line:
                    //     TaskProcessor.ProcessTaskEntry(Rec);
                    // Pages call codeunits — never the other way around. No business
                    // logic in OnAction / OnInsertRecord / OnModifyRecord.
                    if Rec.Status <> Rec.Status::Pending then
                        Error('Only Pending tasks can be processed.');

                    Rec.Status := Rec.Status::Processing;
                    Rec."Processing Started At" := CurrentDateTime;
                    Rec.Modify();

                    // Inline task processing — duplicated from Task Processor codeunit
                    // And it only handles VendorImport, the others just get marked Complete
                    case Rec."Task Type" of
                        Rec."Task Type"::VendorImport:
                            Message('Vendor import would run here. Check Task Log Entries list to run all.');
                        else
                            Message('Task type %1 processed (simulated).', Rec."Task Type");
                    end;

                    Rec.Status := Rec.Status::Complete;
                    Rec."Processing Completed At" := CurrentDateTime;
                    Rec.Modify();
                end;
            }
        }
    }
}
