namespace Techdays.TaskFramework.Processing;

// ANTI-PATTERN: SingleInstance codeunit storing mutable state.
// State is lost when session ends. Breaks completely with background sessions and Job Queue.
// Christian: "A hint that something in the architecture is wrong."
//
// TODO (Step 2 - Separation of Concerns): delete this entire codeunit and the
// self-subscribed event + subscriber in "Task Processor" that feeds it. Persistent
// state belongs in a table field, not in memory. If you need to share state across
// a single run, pass it as a procedure parameter.
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
