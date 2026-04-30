interface "ITask Processor Factory"
{
    procedure GetProcessor(): Interface "ITask Processor";
    procedure GetUpdater(): Interface "ITask Log Updater";
    procedure GetArchiver(): Interface "ITask Archiver";
}
