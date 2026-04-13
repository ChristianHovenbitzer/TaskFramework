namespace Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;

// HANDS-ON: This enum needs to implement "ITask Processor" via enum-interface binding.
// TODO:
//   1. Add "using Techdays.TaskFramework.Processing;" at the top
//   2. Add "implements "ITask Processor"" after the enum name
//   3. Change Extensible to true (so impl app can add task types via enum extension)
//   4. Add DefaultImplementation = "ITask Processor" = "Default Task Processor"
//   5. For each value, add Implementation = "ITask Processor" = <CorrespondingProcessor>
//   6. Move VendorImport and DocumentImport values to the enum extension in the impl app
//      (only None and LogRetention stay in the framework app)
enum 50000 "Task Type" implements "ITask Processor"
{
    Extensible = true;
    DefaultImplementation = "ITask Processor" = "Default Task Processor";

    value(0; None)
    {
        Caption = 'None';
        Implementation = "ITask Processor" = "Default Task Processor";
    }
    value(1; LogRetention)
    {
        Caption = 'Log Retention';
        Implementation = "ITask Processor" = "Log Retention Processor";
    }
}
