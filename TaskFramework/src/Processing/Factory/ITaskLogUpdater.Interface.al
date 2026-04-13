namespace Techdays.TaskFramework.Processing.Factory;

using Techdays.TaskFramework.Core;

interface "ITask Log Updater"
{
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Status");
}
