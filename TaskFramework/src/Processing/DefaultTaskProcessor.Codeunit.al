// TODO: (Step 3 - DI / Strategy via Interfaces): new fallback processor — used as
// the enum's DefaultImplementation and bound to the None value. Errors loudly so
// unbound enum values can't silently no-op.
codeunit 50004 "Default Task Processor" implements "ITask Processor"
{
    Access = Internal;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        NoProcessorErr: Label 'No processor registered for task type %1.';
    begin
        Error(NoProcessorErr, TaskLogEntry."Task Processing Type");
    end;
}
