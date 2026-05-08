// TODO: (Step 3 - DI / Strategy via Interfaces): new contract every task type
// implements. One method for now; error/telemetry params will come in later steps.
interface "ITask Processor"
{
    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry");
}
