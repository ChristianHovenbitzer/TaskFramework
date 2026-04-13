namespace Techdays.TaskFramework.Processing.Factory;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;

// HANDS-ON: Define the factory interface that provides all processing dependencies.
// TODO: Add these procedure signatures:
//   GetProcessor(): Interface "ITask Processor"
//   GetUpdater(): Interface "ITask Log Updater"
//   GetArchiver(): Interface "ITask Archiver"
interface "ITask Processor Factory"
{
    procedure GetProcessor(): Interface "ITask Processor";
    procedure GetUpdater(): Interface "ITask Log Updater";
    procedure GetArchiver(): Interface "ITask Archiver";
}
