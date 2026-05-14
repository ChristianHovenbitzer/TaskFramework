page 50001 "Task Log Entry Card"
{
    PageType = Card;
    SourceTable = "Task Log Entry";
    Caption = 'Task Log Entry';

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
                begin
                    // ANTI-PATTERN: Business logic directly in page trigger.
                    // This bypasses the Task Processor codeunit entirely.
                    //
                    // TODO: (Step 2 - Separation of Concerns)
                    if Rec.Status <> Rec.Status::Pending then
                        Error('Only Pending tasks can be processed.');

                    Rec.Status := Rec.Status::Processing;
                    Rec."Processing Started At" := CurrentDateTime();
                    Rec.Modify(false);

                    // Inline task processing — duplicated from Task Processor codeunit
                    // And it only handles VendorImport, the others just get marked Complete
                    case Rec."Task Processing Type" of
                        Rec."Task Processing Type"::VendorImport:
                            Message('Vendor import would run here. Check Task Log Entries list to run all.');
                        else
                            Message('Task type %1 processed (simulated).', Rec."Task Processing Type");
                    end;

                    Rec.Status := Rec.Status::Complete;
                    Rec."Processing Completed At" := CurrentDateTime();
                    Rec.Modify(false);
                end;
            }
        }
    }
}
