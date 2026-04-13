namespace Techdays.TaskFramework.Processing;

// HANDS-ON: This codeunit uses SingleInstance = true to store processing state.
// SingleInstance means one shared instance per session — state is lost when session ends.
// It breaks completely with background sessions and Job Queue.
//
// TODO:
//   1. Remove "SingleInstance = true" — it is not needed here.
//   2. Instead, the TaskProcessor codeunit should hold a local instance variable
//      and pass state through procedure parameters or local variables.
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
