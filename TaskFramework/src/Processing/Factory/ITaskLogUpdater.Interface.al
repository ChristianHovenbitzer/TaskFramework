// TODO: (Step 4 - Factory Pattern): new role interface (one of three). Narrow on
// purpose — ISP. Tests that only need to mock status updates don't have to stub
// archiving or processing.
interface "ITask Log Updater"
{
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Processing Status");
}
