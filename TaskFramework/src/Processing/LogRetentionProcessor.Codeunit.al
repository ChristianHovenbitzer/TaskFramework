namespace Techdays.TaskFramework.Processing;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Core.Archive;
using Techdays.TaskFramework.Setup;

// HANDS-ON: This codeunit handles the LogRetention task type.
// The logic currently lives in TaskProcessor.ProcessLogRetention() — move it here.
// TODO:
//   1. Add "implements "ITask Processor"" to the codeunit declaration
//   2. Move the log retention logic from TaskProcessor into ProcessTask
//      (read RetentionDays from Setup, delete old archives, update description)
codeunit 50005 "Log Retention Processor" implements "ITask Processor"
{
    Access = Internal;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    begin
        // TODO: Move ProcessLogRetention logic from TaskProcessor here.
    end;
}
