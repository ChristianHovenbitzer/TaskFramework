namespace Techdays.TaskFramework.Processing;

using Techdays.TaskFramework.Core;

interface "ITask Processor"
{
    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry");
}
