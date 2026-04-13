namespace Techdays.TaskFramework.Processing;

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
