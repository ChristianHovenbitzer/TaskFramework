// TODO: (Step 4 - Factory Pattern): add `implements "ITask Log Updater",
// "ITask Archiver", "ITask Processor"` to the codeunit header. Task Processor
// becomes the framework's default for all three roles, with the Factory routing
// between them.

//TODO: (Step 4.5 - Dependency Injection) "Task Processor" implements all newly introduced interfaces
codeunit 50000 "Task Processor" implements "ITask Processor", "ITask Log Updater", "ITask Archiver"
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

    //TODO: (Step 4.5 - Dependency Injection) Overload ProcessTaskEntry to not break existing code, but also allow for dependency injection of ITaskProcessor, ITaskLogUpdater, and ITaskArchiver.
    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
    begin
        ProcessTaskEntry(TaskLogEntry, this, this, this);
    end;

    //TODO: (Step 4.5 - Dependency Injection) Refactor ProcessTaskEntry to take ITaskProcessor, ITaskLogUpdater, and ITaskArchiver as parameters, allowing for dependency injection of every component.
    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry"; ITaskProcessor: Interface "ITask Processor"; ITaskLogUpdater: Interface "ITask Log Updater"; ITaskArchiver: Interface "ITask Archiver")
    var
        IsHandled: Boolean;
    begin
        OnBeforeProcessTask(TaskLogEntry, TaskProcessingState, IsHandled);
        if IsHandled then
            exit;

        ITaskLogUpdater.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Processing);
        ITaskProcessor.ProcessTask(TaskLogEntry);
        ITaskLogUpdater.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Complete);
        ITaskArchiver.Archive(TaskLogEntry);
    end;
    #endregion Process Task Entry

    // TODO: (Step 4.5 - Dependency Injection) All business logic stays in this codeunit, but calls to update log status, archive, and process tasks are routed through their respective interfaces, allowing for dependency injection and isolated tests.
    #region ITask Log Updater
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Processing Status")
    begin
        TaskLogEntry.Status := NewStatus;
        if NewStatus = TaskLogEntry.Status::Processing then
            TaskLogEntry."Processing Started At" := CurrentDateTime
        else
            TaskLogEntry."Processing Completed At" := CurrentDateTime;
        TaskLogEntry.Modify();
    end;
    #endregion

    #region ITask Archiver
    procedure Archive(var TaskLogEntry: Record "Task Log Entry")
    var
        ArchiveEntry: Record "Task Log Archive";
    begin
        ArchiveEntry.Init();
        ArchiveEntry."Entry No." := TaskLogEntry."Entry No.";
        ArchiveEntry."Task Type" := TaskLogEntry."Task Processing Type";
        ArchiveEntry.Status := TaskLogEntry.Status;
        ArchiveEntry.Description := TaskLogEntry.Description;
        ArchiveEntry."Created At" := TaskLogEntry."Created At";
        ArchiveEntry."Processing Started At" := TaskLogEntry."Processing Started At";
        ArchiveEntry."Processing Completed At" := TaskLogEntry."Processing Completed At";
        ArchiveEntry."Last Error Message" := TaskLogEntry."Last Error Message";
        ArchiveEntry."Retry Count" := TaskLogEntry."Retry Count";
        ArchiveEntry.Verbosity := TaskLogEntry.Verbosity;
        ArchiveEntry."Correlation Id" := TaskLogEntry."Correlation Id";
        ArchiveEntry."Archive After Processing" := TaskLogEntry."Archive After Processing";
        ArchiveEntry."Earliest Processing DateTime" := TaskLogEntry."Earliest Processing DateTime";
        ArchiveEntry."Archived At" := CurrentDateTime;
        ArchiveEntry."Archive Reason" := ArchiveEntry."Archive Reason"::Processed;
        ArchiveEntry.Insert();
    end;
    #endregion

    #region ITask Processor
    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        Processor: Interface "ITask Processor";
    begin
        Processor := TaskLogEntry."Task Processing Type";
        Processor.ProcessTask(TaskLogEntry);
    end;
    #endregion ITask Processor
}
