// TODO: (Step 4 - Factory Pattern): add `implements "ITask Log Updater",
// "ITask Archiver", "ITask Processor"` to the codeunit header. Task Processor
// becomes the framework's default for all three roles, with the Factory routing
// between them.
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

    // TODO: (Step 4 - Factory Pattern): split this into two procedures. The bare
    // public version constructs a default `Factory: Codeunit "Task Processor Factory"`
    // and delegates to the Factory-taking overload. The overload routes everything
    // through Factory.GetUpdater() / GetProcessor() / GetArchiver().
    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        IsHandled: Boolean;
        Processor: Interface "ITask Processor";
    begin
        OnBeforeProcessTask(TaskLogEntry, TaskProcessingState, IsHandled);
        if IsHandled then
            exit;

        // TODO: (Step 4 - Factory Pattern): replace the inline status flip with
        // Factory.GetUpdater().UpdateStatus(TaskLogEntry, ::Processing). The
        // UpdateStatus body lives on Task Processor itself (it's the default
        // ITask Log Updater).
        TaskLogEntry.Status := TaskLogEntry.Status::Processing;
        TaskLogEntry."Processing Started At" := CurrentDateTime;
        TaskLogEntry.Modify();

        // TODO: (Step 4 - Factory Pattern): wrap this dispatch in a new
        // ProcessTask(var TaskLogEntry) method on Task Processor (it's the default
        // ITask Processor). Then call Factory.GetProcessor().ProcessTask(...) here.
        Processor := TaskLogEntry."Task Processing Type";
        Processor.ProcessTask(TaskLogEntry);

        // TODO: (Step 4 - Factory Pattern): replace with
        // Factory.GetUpdater().UpdateStatus(TaskLogEntry, ::Complete).
        TaskLogEntry.Status := TaskLogEntry.Status::Complete;
        TaskLogEntry."Processing Completed At" := CurrentDateTime;
        TaskLogEntry.Modify();

        if TaskLogEntry."Archive After Processing" then
            ArchiveEntry(TaskLogEntry);
    end;
    #endregion Process Task Entry

    // TODO: (Step 4 - Factory Pattern): rename to `Archive` and promote to a public
    // procedure — Task Processor implements ITask Archiver and this method is the
    // body of that contract. The Factory will reach this via GetArchiver().
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
