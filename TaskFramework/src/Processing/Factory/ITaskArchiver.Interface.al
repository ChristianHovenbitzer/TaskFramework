namespace Techdays.TaskFramework.Processing.Factory;

using Techdays.TaskFramework.Core;

interface "ITask Archiver"
{
    procedure Archive(var TaskLogEntry: Record "Task Log Entry");
}
