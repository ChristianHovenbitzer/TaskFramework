// TODO: (Step 3 - DI / Strategy via Interfaces): the monster CASE on Task Type is
// gone. Routing is now an enum→interface dispatch (see ProcessTaskEntry below).
// Per-type bodies moved to ITask Processor implementations. The framework no longer
// references Vendor.
codeunit 50000 "Task Processor"
{
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessTask(var TaskLogEntry: Record "Task Log Entry"; TaskProcessingState: Codeunit "Task Processing State"; var IsHandled: Boolean)
    begin
    end;


    #region Process Task Entry
    var
        TaskProcessingState: Codeunit "Task Processing State";
        DueDatePendingFilterTok: Label '%1|<%2', Locked = true;

    procedure GetTaskProcessingState(): Codeunit "Task Processing State"
    begin
        exit(TaskProcessingState);
    end;

    procedure ProcessAllPendingTasks()
    var
        TaskLogEntry: Record "Task Log Entry";
    begin
        // ANTI-PATTERN: No error isolation.
        // If ProcessTaskEntry throws for entry 3 of 10, entries 4-10 never run.
        // Step 6 will fix this with proper error handling.
        Clear(TaskProcessingState);

        TaskLogEntry.SetRange(Status, TaskLogEntry.Status::Pending);
        TaskLogEntry.SetFilter("Earliest Processing DateTime", DueDatePendingFilterTok, 0DT, CurrentDateTime());
        if TaskLogEntry.FindSet(true) then
            repeat
                ProcessTaskEntry(TaskLogEntry);
                TaskProcessingState.IncrementProcessedCount();
                TaskProcessingState.SetLastProcessed(TaskLogEntry."Entry No.");
            until TaskLogEntry.Next() = 0;
    end;

    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        IsHandled: Boolean;
        Processor: Interface "ITask Processor";
    begin
        OnBeforeProcessTask(TaskLogEntry, TaskProcessingState, IsHandled);
        if IsHandled then
            exit;

        TaskLogEntry.Status := TaskLogEntry.Status::Processing;
        TaskLogEntry."Processing Started At" := CurrentDateTime();
        TaskLogEntry.Modify(false);

        // TODO: (Step 3 - DI / Strategy via Interfaces): single-line dispatch via the
        // enum's Implementation binding replaces the entire CASE block.
        Processor := TaskLogEntry."Task Processing Type";
        Processor.ProcessTask(TaskLogEntry);

        TaskLogEntry.Status := TaskLogEntry.Status::Complete;
        TaskLogEntry."Processing Completed At" := CurrentDateTime();
        TaskLogEntry.Modify(false);

        ArchiveEntry(TaskLogEntry);
    end;
    #endregion Process Task Entry

    local procedure ArchiveEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        Archive: Record "Task Log Archive";
    begin
        if not TaskLogEntry."Archive After Processing" then
            exit;

        Archive.Init();
        Archive."Entry No." := TaskLogEntry."Entry No.";
        Archive."Task Type" := TaskLogEntry."Task Processing Type";
        Archive.Status := TaskLogEntry.Status;
        Archive.Description := TaskLogEntry.Description;
        Archive."Created At" := TaskLogEntry."Created At";
        Archive."Processing Started At" := TaskLogEntry."Processing Started At";
        Archive."Processing Completed At" := TaskLogEntry."Processing Completed At";
        Archive."Last Error Message" := TaskLogEntry."Last Error Message";
        Archive."Retry Count" := TaskLogEntry."Retry Count";
        Archive.Verbosity := TaskLogEntry.Verbosity;
        Archive."Correlation Id" := TaskLogEntry."Correlation Id";
        Archive."Archive After Processing" := TaskLogEntry."Archive After Processing";
        Archive."Earliest Processing DateTime" := TaskLogEntry."Earliest Processing DateTime";
        Archive."Archived At" := CurrentDateTime();
        Archive."Archive Reason" := Archive."Archive Reason"::Processed;
        Archive.Insert(false);
    end;
}
