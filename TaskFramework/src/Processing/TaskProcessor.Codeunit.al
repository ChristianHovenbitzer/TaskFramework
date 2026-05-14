// TODO: (Step 4.5 - Dependency Injection) "Task Processor" implements all newly
// introduced interfaces. Add `implements "ITask Processor", "ITask Log Updater",
// "ITask Archiver"` to the header — Task Processor stays the framework's default
// for all three roles, it just exposes them as injectable contracts now.
codeunit 50000 "Task Processor"
{
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessTask(var TaskLogEntry: Record "Task Log Entry"; TaskProcessingState: Codeunit "Task Processing State"; var IsHandled: Boolean)
    begin
    end;


    #region Process Task Entry
    var
        TaskProcessingState: Codeunit "Task Processing State";

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
        Clear(TaskProcessingState);

        TaskLogEntry.SetRange(Status, TaskLogEntry.Status::Pending);
        TaskLogEntry.SetFilter("Earliest Processing DateTime", '%1|<%2', 0DT, CurrentDateTime);
        if TaskLogEntry.FindSet(true) then
            repeat
                ProcessTaskEntry(TaskLogEntry);
                TaskProcessingState.IncrementProcessedCount();
                TaskProcessingState.SetLastProcessed(TaskLogEntry."Entry No.");
            until TaskLogEntry.Next() = 0;
    end;

    // TODO: (Step 4.5 - Dependency Injection) Overload ProcessTaskEntry so existing
    // callers keep working: this bare version stays public and delegates to a new
    // overload that takes ITask Processor, ITask Log Updater, and ITask Archiver as
    // parameters — passing `this` for all three (Task Processor is its own default).
    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        IsHandled: Boolean;
        Processor: Interface "ITask Processor";
    begin
        OnBeforeProcessTask(TaskLogEntry, TaskProcessingState, IsHandled);
        if IsHandled then
            exit;

        // TODO: (Step 4.5 - Dependency Injection) Route this status flip through
        // the injected ITask Log Updater (UpdateStatus(TaskLogEntry, ::Processing))
        // — the injected role owns the change, not the inline code.
        TaskLogEntry.Status := TaskLogEntry.Status::Processing;
        TaskLogEntry."Processing Started At" := CurrentDateTime;
        TaskLogEntry.Modify();

        // TODO: (Step 4.5 - Dependency Injection) Route this dispatch through the
        // injected ITask Processor (ITaskProcessor.ProcessTask(TaskLogEntry)). The
        // enum -> interface lookup moves into a ProcessTask method on Task Processor,
        // which is its own default ITask Processor.
        Processor := TaskLogEntry."Task Processing Type";
        Processor.ProcessTask(TaskLogEntry);

        // TODO: (Step 4.5 - Dependency Injection) Route this through the injected
        // ITask Log Updater as well (UpdateStatus(TaskLogEntry, ::Complete)).
        TaskLogEntry.Status := TaskLogEntry.Status::Complete;
        TaskLogEntry."Processing Completed At" := CurrentDateTime;
        TaskLogEntry.Modify();

        if TaskLogEntry."Archive After Processing" then
            ArchiveEntry(TaskLogEntry);
    end;
    #endregion Process Task Entry

    // TODO: (Step 4.5 - Dependency Injection) All business logic stays in this
    // codeunit. Rename `ArchiveEntry` to `Archive` and promote it to a public
    // procedure — it becomes the body of Task Processor's ITask Archiver contract.
    // Give UpdateStatus and ProcessTask the same treatment so each role is a real,
    // injectable procedure.
    local procedure ArchiveEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        Archive: Record "Task Log Archive";
    begin
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
        Archive."Archived At" := CurrentDateTime;
        Archive."Archive Reason" := Archive."Archive Reason"::Processed;
        Archive.Insert();
    end;
}
