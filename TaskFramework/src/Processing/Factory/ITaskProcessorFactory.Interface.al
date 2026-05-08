// TODO: (Step 4 - Factory Pattern): new factory contract — the only interface
// callers of ProcessTaskEntry need. Bundles the three role getters; the role
// interfaces themselves stay an internal contract between factory and Task Processor.
interface "ITask Processor Factory"
{
    procedure GetProcessor(): Interface "ITask Processor";
    procedure GetUpdater(): Interface "ITask Log Updater";
    procedure GetArchiver(): Interface "ITask Archiver";
}
