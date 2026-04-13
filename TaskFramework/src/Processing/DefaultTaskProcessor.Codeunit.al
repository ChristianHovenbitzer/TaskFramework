namespace Techdays.TaskFramework.Processing;

using Techdays.TaskFramework.Core;

// HANDS-ON: This is the default (fallback) processor for task types with no specific implementation.
// It should implement the "ITask Processor" interface.
// TODO:
//   1. Add "implements "ITask Processor"" to the codeunit declaration
//   2. Implement the ProcessTask procedure — it should Error() with a message
//      indicating no processor is registered for the given task type.
codeunit 50004 "Default Task Processor" implements "ITask Processor"
{
    Access = Internal;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        NoProcessorErr: Label 'No processor registered for task type %1.';
    begin
        Error(NoProcessorErr, TaskLogEntry."Task Type");
    end;
}
