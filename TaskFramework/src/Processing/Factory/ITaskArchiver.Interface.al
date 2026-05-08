// TODO: (Step 4 - Factory Pattern): new role interface (one of three). Narrow on
// purpose — ISP. Mirrors ITask Log Updater in shape and intent.
interface "ITask Archiver"
{
    procedure Archive(var TaskLogEntry: Record "Task Log Entry");
}
