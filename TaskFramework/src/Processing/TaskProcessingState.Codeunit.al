// TODO: (Step 2 - Separation of Concerns): dropped SingleInstance. Task Processor
// now holds an instance of this codeunit as a local var.
codeunit 50003 "Task Processing State"
{
    var
        LastProcessedEntryNo: Integer;
        ProcessedCount: Integer;

    procedure SetLastProcessed(EntryNo: Integer)
    begin
        LastProcessedEntryNo := EntryNo;
    end;

    procedure GetLastProcessed(): Integer
    begin
        exit(LastProcessedEntryNo);
    end;

    procedure IncrementProcessedCount()
    begin
        ProcessedCount += 1;
    end;

    procedure GetProcessedCount(): Integer
    begin
        exit(ProcessedCount);
    end;
}
