// ANTI-PATTERN: SingleInstance codeunit storing mutable state.
// State is lost when session ends. Breaks completely with background sessions and Job Queue.
// Christian: "A hint that something in the architecture is wrong."
// Step 2/3 will remove this — state belongs in tables or procedure parameters.
codeunit 50003 "Task Processing State"
{
    SingleInstance = true;

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
