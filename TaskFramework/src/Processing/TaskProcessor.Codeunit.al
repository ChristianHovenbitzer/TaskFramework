// TODO: (Step 4 - Factory Pattern): Task Processor now wears three hats — it's
// the framework's default ITask Log Updater, ITask Archiver, and ITask Processor.
// The Factory routes between these defaults and any test-injected overrides.
codeunit 50000 "Task Processor" implements "ITask Log Updater", "ITask Archiver", "ITask Processor"
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
        TaskLogEntry.SetRange(Status, TaskLogEntry.Status::Pending);
        TaskLogEntry.SetFilter("Earliest Processing DateTime", DueDatePendingFilterTok, 0DT, CurrentDateTime());

        ProcessAllPendingTasks(TaskLogEntry);
    end;

    procedure ProcessAllPendingTasks(var TaskLogEntry: Record "Task Log Entry")
    begin
        // ANTI-PATTERN: No error isolation.
        // If ProcessTaskEntry throws for entry 3 of 10, entries 4-10 never run.
        // Step 6 will fix this with proper error handling.
        Clear(TaskProcessingState);

        TaskLogEntry.ReadIsolation(IsolationLevel::UpdLock);
        if TaskLogEntry.FindSet() then
            repeat
                ProcessTaskEntry(TaskLogEntry);
                TaskProcessingState.IncrementProcessedCount();
                TaskProcessingState.SetLastProcessed(TaskLogEntry."Entry No.");
            until TaskLogEntry.Next() = 0;
    end;

    // TODO: (Step 4 - Factory Pattern): public bare overload — production entry
    // point. Constructs a default Factory and delegates to the Factory-taking
    // overload below. The bare-vs-with-factory split is the test seam.
    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        Factory: Codeunit "Task Processor Factory";
    begin
        ProcessTaskEntry(TaskLogEntry, Factory);
    end;


    // ANTI-PATTERN: Dependency injection without a factory.
    // procedure ProcessTaskEntry(
    //     var TaskLogEntry: Record "Task Log Entry";
    //     LogUpdater: Interface "ITask Log Updater";
    //     Processor: Interface "ITask Processor";
    //     Archiver: Interface "ITask Archiver")
    // var
    //     IsHandled: Boolean;
    // begin
    //     OnBeforeProcessTask(TaskLogEntry, TaskProcessingState, IsHandled);
    //     if IsHandled then
    //         exit;

    //     LogUpdater.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Processing);
    //     Processor.ProcessTask(TaskLogEntry);
    //     LogUpdater.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Complete);

    //     if TaskLogEntry."Archive After Processing" then
    //         Archiver.Archive(TaskLogEntry);
    // end;

    // TODO: (Step 4 - Factory Pattern): Factory-taking overload — every status
    // touch, the processor dispatch, and the archive call now route through the
    // factory. Inline status flips and the local ArchiveEntry call are gone.
    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry"; Factory: Interface "ITask Processor Factory")
    var
        IsHandled: Boolean;
    begin
        OnBeforeProcessTask(TaskLogEntry, TaskProcessingState, IsHandled);
        if IsHandled then
            exit;

        Factory.GetUpdater().UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Processing);
        Factory.GetProcessor().ProcessTask(TaskLogEntry);
        Factory.GetUpdater().UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Complete);

        Factory.GetArchiver().Archive(TaskLogEntry);
    end;

    #endregion Process Task Entry

    #region ITask Log Updater
    // TODO: (Step 4 - Factory Pattern): body extracted from the inline status
    // flips that were in ProcessTaskEntry. This is Task Processor's default
    // implementation of ITask Log Updater.
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Processing Status")
    begin
        TaskLogEntry.Status := NewStatus;
        if NewStatus = TaskLogEntry.Status::Processing then
            TaskLogEntry."Processing Started At" := CurrentDateTime()
        else
            TaskLogEntry."Processing Completed At" := CurrentDateTime();
        TaskLogEntry.Modify(false);
    end;
    #endregion

    #region ITask Archiver
    // TODO: (Step 4 - Factory Pattern): renamed from `local procedure ArchiveEntry`
    // and promoted to a public procedure — this is Task Processor's default
    // implementation of ITask Archiver.
    procedure Archive(var TaskLogEntry: Record "Task Log Entry")
    var
        ArchiveEntry: Record "Task Log Archive";
    begin
        if not TaskLogEntry."Archive After Processing" then
            exit;

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
        ArchiveEntry."Archived At" := CurrentDateTime();
        ArchiveEntry."Archive Reason" := ArchiveEntry."Archive Reason"::Processed;
        ArchiveEntry.Insert(false);
    end;
    #endregion


    // TODO: (Step 4 - Factory Pattern): wraps the Step 3 enum→interface dispatch
    // so Task Processor can serve as its own default ITask Processor.
    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        Processor: Interface "ITask Processor";
    begin
        Processor := TaskLogEntry."Task Processing Type";
        Processor.ProcessTask(TaskLogEntry);
    end;
}
