namespace Techdays.TaskFramework.Processing;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Core.Archive;
using Techdays.TaskFramework.Processing.Factory;
using Techdays.TaskFramework.Setup;

codeunit 50000 "Task Processor" implements "ITask Log Updater", "ITask Archiver", "ITask Processor"
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
        TaskLogEntry.SetRange(Status, TaskLogEntry.Status::Pending);
        TaskLogEntry.SetFilter("Earliest Processing DateTime", '%1|<%2', 0DT, CurrentDateTime);

        ProcessAllPendingTasks(TaskLogEntry);
    end;

    procedure ProcessAllPendingTasks(var TaskLogEntry: Record "Task Log Entry")
    begin
        // ANTI-PATTERN: No error isolation.
        // If ProcessTaskEntry throws for entry 3 of 10, entries 4-10 never run.
        //
        // TODO: (Step 6 - Collectible Errors): change Check Line's Error() calls to
        // LogError(ErrorLog, ..., IsBlocking) writing to the "Task Error Log" table,
        // and have Post Batch collect all errors before deciding whether to post.
        // Show the full error list (Message or Error Log page) instead of stopping
        // on the first failure.
        Clear(TaskProcessingState);

        TaskLogEntry.ReadIsolation(IsolationLevel::UpdLock);
        if TaskLogEntry.FindSet() then
            repeat
                ProcessTaskEntry(TaskLogEntry);
                TaskProcessingState.IncrementProcessedCount();
                TaskProcessingState.SetLastProcessed(TaskLogEntry."Entry No.");
            until TaskLogEntry.Next() = 0;
    end;

    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        Factory: Codeunit "Task Processor Factory";
    begin
        ProcessTaskEntry(TaskLogEntry, Factory);
    end;

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

        if TaskLogEntry."Archive After Processing" then
            Factory.GetArchiver().Archive(TaskLogEntry);
    end;

    #endregion Process Task Entry

    #region ITask Log Updater
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Status")
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
        ArchiveEntry."Task Type" := TaskLogEntry."Task Type";
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


    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        Processor: Interface "ITask Processor";
    begin
        Processor := TaskLogEntry."Task Type";
        Processor.ProcessTask(TaskLogEntry);
    end;
}
