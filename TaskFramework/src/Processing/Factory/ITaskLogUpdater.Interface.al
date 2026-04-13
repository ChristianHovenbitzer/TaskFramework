namespace Techdays.TaskFramework.Processing.Factory;

using Techdays.TaskFramework.Core;

// HANDS-ON: Define the ITask Log Updater interface.
// TODO: Add a procedure signature: UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Status")
interface "ITask Log Updater"
{
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Status");
}
