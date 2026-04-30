// External callers create entries by POSTing to this API page.
// The OnInsertRecord trigger delegates to Task Entry Facade — direct table writes are not supported.
page 50045 "Task Entry API"
{
    PageType = API;
    APIPublisher = 'techdays';
    APIGroup = 'taskFramework';
    APIVersion = 'v1.0';
    EntityName = 'taskEntry';
    EntitySetName = 'taskEntries';
    SourceTable = "Task Log Entry";
    Caption = 'Task Entry API';
    ODataKeyFields = "Entry No.";
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Editable = false;
                }
                field(taskType; Rec."Task Processing Type")
                {
                    Caption = 'Task Type';
                }
                field(payload; PayloadText)
                {
                    Caption = 'Payload';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(correlationId; Rec."Correlation Id")
                {
                    Caption = 'Correlation Id';
                    Editable = false;
                }
            }
        }
    }

    var
        PayloadText: Text;

    trigger OnAfterGetRecord()
    begin
        PayloadText := Rec.GetPayloadText();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TaskProcessor: Codeunit "Task Processor";
        EntryNo: Integer;
    begin
        Rec.SetPayloadText(PayloadText);
        Rec.Insert(true);
        TaskProcessor.ProcessTaskEntry(Rec);

        exit(false); // Record was already inserted by the processor, so skip the default insert
    end;
}
