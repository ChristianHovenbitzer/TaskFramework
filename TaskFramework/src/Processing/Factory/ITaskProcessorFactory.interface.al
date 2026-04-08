namespace Techdays.TaskFramework.Processing.Factory;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;

interface "ITask Processor Factory"
{
    procedure GetProcessor(): Interface "ITask Processor";
    procedure SetProcessor(TaskProcessor: Interface "ITask Processor");
    procedure GetUpdater(): Interface "ITask Log Updater";
    procedure SetUpdater(TaskLogUpdater: Interface "ITask Log Updater");
    procedure GetArchiver(): Interface "ITask Archiver";
    procedure SetArchiver(TaskArchiver: Interface "ITask Archiver");
}
