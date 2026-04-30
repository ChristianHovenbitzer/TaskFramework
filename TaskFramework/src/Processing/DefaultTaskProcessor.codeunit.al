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
